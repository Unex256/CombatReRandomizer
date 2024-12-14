local MathUtils = {}

-- Seeds the random number generator. Call this once at the start of your program for better randomness.
function MathUtils.seedRandom()
    math.randomseed(os.time())
end

-- Gets a random floating point number between 0 and 100
function MathUtils.getRandomNumber0to100()
    return math.random() * 100.0  -- Generates a float between 0 and 100
end

-- Checks if the given number is greater or equal to a random floating point number between 0 and 100
function MathUtils.isGreaterOrEqualThanRandom(num)
    local randomNum = MathUtils.getRandomNumber0to100()
    return num >= randomNum
end

-- Checks if the given number is less than a random number between 0 and 100
function MathUtils.isLessThanRandom(num)
    local randomNum = MathUtils.getRandomNumber0to100()
    return num < randomNum
end

-- Rounds a number to the nearest integer
function MathUtils.mathRound(num)
    return math.floor(num + 0.5)
end

-- Floors a number to the nearest lower integer
function MathUtils.mathFloor(num)
    return math.floor(num)
end

-- Returns a random number in various formats:
-- If no arguments are provided, returns a random number between 0 and 1 (exclusive)
-- If one argument is provided, returns a random integer between 1 and 'to' (inclusive)
-- If two arguments are provided, returns a random integer between 'from' and 'to' (inclusive)
function MathUtils.random(from, to)
    if from == nil and to == nil then
        return math.random()  -- Random float between 0 and 1
    elseif to == nil then
        assert(type(from) == "number", "Argument 'from' must be a number")
        return math.random(1, from)  -- Random integer between 1 and 'from'
    else
        assert(type(from) == "number" and type(to) == "number", "Arguments 'from' and 'to' must be numbers")
        return math.random(from, to)  -- Random integer between 'from' and 'to'
    end
end

return MathUtils
