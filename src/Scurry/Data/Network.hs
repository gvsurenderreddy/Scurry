{-# LANGUAGE DeriveDataTypeable, CPP, ForeignFunctionInterface #-}
module Scurry.Data.Network (
    IPV4Addr,
    IPPort(..),
    VPNAddr,
    inet_ntoa,
    inet_addr,

    module Network.Socket,
) where

import Data.Word

import Control.Monad
import System.IO.Unsafe (unsafePerformIO)

import qualified Network.Socket as INET (inet_addr,
                                         inet_ntoa)
import Network.Socket hiding (send, sendTo,
                              recv, recvFrom,
                              PortNum, -- WhyTF is this exposed
                              inet_addr, inet_ntoa)
-- import Network.Socket.ByteString

newtype IPV4Addr = MkIPV4Addr { unIPV4Addr :: HostAddress }
newtype IPPort   = MkIPPort   { unIPPort   :: PortNumber  }
newtype VPNAddr  = MkVPNAddr  { unVpnAddr  :: IPV4Addr    }

inet_addr :: String -> Maybe IPV4Addr
inet_addr = unsafePerformIO . catchToMaybe . mk
    where mk v = liftM MkIPV4Addr (INET.inet_addr v)

inet_ntoa :: IPV4Addr -> Maybe String
inet_ntoa (MkIPV4Addr a) = unsafePerformIO unmk
    where unmk = catchToMaybe . INET.inet_ntoa $ a

catchToMaybe :: (IO a) -> IO (Maybe a)
catchToMaybe a = catch (liftM Just a) (\_ -> return Nothing)

-- Read instances! Note, these suck and need to be fixed.
instance Read IPV4Addr where
    readsPrec _ r = case a of
                         (Just a') -> [(a',"")]
                         Nothing   -> error "IPV4Address: no parse!"
        where a = inet_addr r

instance Read IPPort where
    readsPrec _ r = [(p',"")]
        where p  = read r :: Word16
              p' = MkIPPort . fromIntegral $ p

instance Read VPNAddr where
    readsPrec _ r = [(MkVPNAddr v,"")]
        where v = read r


instance Show IPV4Addr where
    show a = case inet_ntoa a of
                  Just s -> s
                  Nothing -> error "This should never happen evar! O_o"

instance Show VPNAddr where
    show a = case inet_ntoa (unVpnAddr a) of
                  Just s -> s
                  Nothing -> error "This should never happen evar! O_o"

instance Show IPPort where
    show p = show . unIPPort $ p
