{-# LANGUAGE BangPatterns, ScopedTypeVariables #-}
-- |
-- Module    : Statistics.Distribution
-- Copyright : (c) 2009 Bryan O'Sullivan
-- License   : BSD3
--
-- Maintainer  : bos@serpentine.com
-- Stability   : experimental
-- Portability : portable
--
-- Types classes for probability distrubutions

module Statistics.Distribution
    (
      -- * Type classes
      Distribution(..)
    , DiscreteDistr(..)
    , ContDistr(..)
    , Mean(..)
    , Variance(..)
      -- * Helper functions
    , findRoot
    , cdfFromProbability
    ) where

import qualified Data.Vector.Unboxed as U

-- | Type class common to all distributions. Only c.d.f. could be
-- defined for both discrete and continous distributions.
class Distribution d where
    -- | Cumulative distribution function.  The probability that a
    -- random variable /X/ is less or equal than /x/,
    -- i.e. P(/X/&#8804;/x/). 
    cumulative :: d -> Double -> Double


-- | Discrete probability distribution.
class Distribution  d => DiscreteDistr d where
    -- | Probability of n-th outcome.
    probability :: d -> Int -> Double


-- | Continuous probability distributuion
class Distribution d => ContDistr d where
    -- | Probability density function. Probability that random
    -- variable /X/ lies in the infinitesimal interval
    -- [/x/,/x+/&#948;/x/) equal to /density(x)/&#8901;&#948;/x/
    density :: d -> Double -> Double

    -- | Inverse of the cumulative distribution function. The value
    -- /x/ for which P(/X/&#8804;/x/) = /p/.
    quantile :: d -> Double -> Double


-- | Type class for distributions with mean.
class Distribution d => Mean d where
    mean :: d -> Double


-- | Type class for distributions with variance.
class Mean d => Variance d where
    variance :: d -> Double


data P = P {-# UNPACK #-} !Double {-# UNPACK #-} !Double

-- | Approximate the value of /X/ for which P(/x/>/X/)=/p/.
--
-- This method uses a combination of Newton-Raphson iteration and
-- bisection with the given guess as a starting point.  The upper and
-- lower bounds specify the interval in which the probability
-- distribution reaches the value /p/.
findRoot :: ContDistr d => 
            d                   -- ^ Distribution
         -> Double              -- ^ Probability /p/
         -> Double              -- ^ Initial guess
         -> Double              -- ^ Lower bound on interval
         -> Double              -- ^ Upper bound on interval
         -> Double
findRoot d prob = loop 0 1
  where
    loop !(i::Int) !dx !x !lo !hi
      | abs dx <= accuracy || i >= maxIters = x
      | otherwise                           = loop (i+1) dx'' x'' lo' hi'
      where
        err                   = cumulative d x - prob
        P lo' hi' | err < 0   = P x hi
                  | otherwise = P lo x
        pdf                   = density d x
        P dx' x' | pdf /= 0   = P (err / pdf) (x - dx)
                 | otherwise  = P dx x
        P dx'' x''
            | x' < lo' || x' > hi' || pdf == 0 = let y = (lo' + hi') / 2
                                                 in  P (y-x) y
            | otherwise                        = P dx' x'
    accuracy = 1e-15
    maxIters = 150

-- | Construct c.d.f. for discrete distribution. It just sums
-- probabilities from /0/ to /floor x/.
cdfFromProbability :: DiscreteDistr d => d -> Double -> Double
cdfFromProbability d =
  -- Return value is forced to be less than 1 to guard againist roundoff errors. 
  -- ATTENTION! this check should be removed for testing or it could mask bugs.
  min 1 . U.sum . U.map (probability d) . U.enumFromTo 0 . floor
{-# INLINE cdfFromProbability #-}