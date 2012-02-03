# (The MIT License)
# 
# Copyright (c) 2010 Nicolas Sanguinetti, http://nicolassanguinetti.info
# Copyright (c) 2012 Brandon Dewitt, http://abrandoned.com
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the 'Software'), 
# to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, 
# and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS 
# IN THE SOFTWARE.

require 'chronic'
require 'active_support/core_ext'
require 'active_record'
require 'squeel'

Squeel.configure do |config|
  config.load_core_extensions :hash  
end

require "birddog/version"
require "birddog/field_conditions"
require "birddog/boolean_expression"
require "birddog/date_expression"
require "birddog/numeric_expression"
require "birddog/searchable"
require "birddog/birddog"
