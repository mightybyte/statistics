{-# LANGUAGE DeriveDataTypeable, TypeFamilies #-}
-- |
-- Module    : Statistics.Distribution.Geometric
-- Copyright : (c) 2009 Bryan O'Sullivan
-- License   : BSD3
--
-- Maintainer  : bos@serpentine.com
-- Stability   : experimental
-- Portability : portable
--
-- The Geometric distribution. This is the probability distribution of
-- the number of Bernoulli trials needed to get one success, supported
-- on the set [1,2..].
--
-- This distribution is sometimes referred to as the /shifted/
-- geometric distribution, to distinguish it from a variant measuring
-- the number of failures before the first success, defined over the
-- set [0,1..].

module Statistics.Distribution.Geometric
    (
      GeometricDistribution
    -- * Constructors
    , geometric
    -- ** Accessors
    , gdSuccess
    ) where

import Data.Typeable (Typeable)
import qualified Statistics.Distribution as D

newtype GeometricDistribution = GD {
      gdSuccess :: Double
    } deriving (Eq, Read, Show, Typeable)

instance D.Distribution GeometricDistribution where
    type DistrSample GeometricDistribution = Double
    cumulative = cumulative

instance D.DiscreteDistr GeometricDistribution where
    probability = probability

instance D.Mean GeometricDistribution where
    mean (GD s) = 1 / s
    {-# INLINE mean #-}

instance D.Variance GeometricDistribution where
    variance (GD s) = (1 - s) / (s * s)
    stdDev = D.stdDevUni
    {-# INLINE variance #-}

instance D.MaybeMean GeometricDistribution where
    maybeMean = Just . D.mean

instance D.MaybeVariance GeometricDistribution where
    maybeStdDev   = Just . D.stdDev
    maybeVariance = Just . D.variance


-- | Create geometric distribution.
geometric :: Double                -- ^ Success rate
          -> GeometricDistribution
geometric x
  | x >= 0 && x <= 1 = GD x
  | otherwise        =
    error $ "Statistics.Distribution.Geometric.geometric: probability must be in [0,1] range. Got " ++ show x
{-# INLINE geometric #-}

probability :: GeometricDistribution -> Int -> Double
probability (GD s) n | n < 1     = 0
                     | otherwise = s * (1-s) ** (fromIntegral n - 1)
{-# INLINE probability #-}

cumulative :: GeometricDistribution -> Double -> Double
cumulative (GD s) x | x < 1     = 0
                    | otherwise = 1 - (1-s) ^ (floor x :: Int)
{-# INLINE cumulative #-}
