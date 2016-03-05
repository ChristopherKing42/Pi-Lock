{-# LANGUAGE OverloadedStrings, LambdaCase #-}
module KeyManagement where

import Control.Concurrent (threadDelay,forkIO)
import Control.Exception (bracket, handle, try)
import qualified Data.ByteString as B
import Data.List (isSuffixOf)
import System.INotify
import System.IO (withBinaryFile, IOMode(..))
import System.Posix.Directory

-- | `randomizeFile i n` fills file `i` with `n` random bytes from `/dev/urandom`
randomizeFile :: Int -> FilePath -> IO ()
randomizeFile bytes name = withBinaryFile "/dev/urandom" ReadMode $ \rand ->
    B.hGet rand bytes >>= B.writeFile name

-- | Monitor a directory for new keys, and randomize any new empty keys
randomizeNewKeys :: Int -> FilePath -> IO a
randomizeNewKeys bytes dir = withINotify $ \int -> do
    addWatch int [Create] dir $ \case
        Created False newkey -> inDir dir $ do
            if ".key" `isSuffixOf` newkey
                then do
                    putStr "New Key: "
                    putStrLn newkey
                    content <- readFile newkey
                    if null content --Only randomize empty keys, so we don't overwite good ones by accident
                        then putStrLn "randomized" >> randomizeFile bytes newkey
                        else return ()
                else return ()
        other -> return ()

    let sleep = threadDelay maxBound >> sleep in sleep --So `withINotify` does not close prematurely

-- | Finds a key file in a directory and returns its path
getKeyFile :: FilePath -> IO (Maybe FilePath)
getKeyFile name = bracket (openDirStream name) closeDirStream igo
    where
        igo dir = do
            filepath <- readDirStream dir
            if null filepath then return Nothing else --A null path means the directory has no more files
                if ".key" `isSuffixOf` filepath
                    then return $ Just filepath
                    else igo dir

-- | Run a computation in a different directory. It moves back once its done.
inDir :: FilePath -> IO a -> IO a
inDir dir action = bracket getWorkingDirectory changeWorkingDirectory $ const $ do
                        changeWorkingDirectory dir
                        action

-- | Checks if the file matches a file in the directory (name and content). When comparing content, it will read the file in the directory completely, and only look at enough of the file in the directory to compare them for equality.
fileIn :: FilePath -> FilePath -> IO Bool
fileIn fileName dirName =
    withBinaryFile fileName ReadMode $ \file -> -- file is file
        inDir dirName $
            handle (const $ return False :: IOError -> IO Bool) $ --If this file does not exist, return false
                withBinaryFile fileName ReadMode $ \file' -> do -- file' if file in directory
                    fileContent' <- B.hGetContents file'
                    fileContent  <- B.hGetSome file $ 1 + B.length fileContent' -- We only need to look at at most the length of file' + 1.
                    return $ fileContent == fileContent'

-- | Checks for new keys
checkKeys
    :: Int -- ^ Number of bytes to randomize new key with
    -> Int -- ^ Number of microseconds it takes for things to mount
    -> FilePath -- ^ Where valid keys are stored
    -> FilePath -- ^ Where to look for keys to check against
    -> (FilePath -> FilePath -> IO ()) -- ^ How to respond to a good key. Called with the directory and key file name.
    -> (FilePath -> Maybe FilePath -> Maybe IOError -> IO ()) -- ^ How to respond to a bady key. Called with the directory and key file name and any IOErrors.
    -> IO a -- ^ This function never returns

checkKeys bytes wait keys metadir good bad = withINotify $ \int -> do
    changeWorkingDirectory metadir
    addWatch int [AllEvents] metadir $ (\case
        Created True dir -> putStr "New USB device: " >> putStrLn dir >> threadDelay wait >> checkDir bytes keys dir good bad
        other -> print other --
        )
    let sleep = threadDelay maxBound >> sleep in sleep --So `withINotify` does not close prematurely

-- | Checks a directory for a key
checkDir
  :: Int -- ^ Number of bytes to randomize new key with
  -> FilePath -- ^ Where valid keys are stored
  -> FilePath -- ^ Where to look for keys to check against
  -> (FilePath -> FilePath -> IO a) -- ^ How to respond to a good key. Called with the directory and key file name.
  -> (FilePath -> Maybe FilePath -> Maybe IOError -> IO a) -- ^ How to respond to a bady key. Called with the directory and key file name and any IOErrors.
  -> IO a --Returns with the result of the callback

checkDir bytes keys dir good bad = (try $ getKeyFile dir) >>= \case
    Right Nothing -> bad dir Nothing Nothing --No key file
    Left e -> bad dir Nothing (Just e) --Trying to find key file resulted in error
    Right (Just key) -> do
        -- act is Either e (IO ()), not Either e (). This way errors are not caught that should be propagated.
        act <- try $ do
            valid <- inDir dir $ key `fileIn` keys
            if valid
            then do
                putStr "Randomizing " >> putStr key
                inDir keys $ randomizeFile bytes key --Rerandomize key to prevent copying
                inDir keys (B.readFile key) >>= inDir dir . B.writeFile key
                return $ good dir key
            else return $ bad dir (Just key) Nothing --The key file was wrong
        case act of
            Right act -> act
            Left e -> bad dir (Just key) (Just e)
