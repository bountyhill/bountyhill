# encoding: UTF-8

# Load the rails application
require File.expand_path('../application', __FILE__)

# Solve the file encoding problem
Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

# Initialize the rails application
Bountyhill::Application.initialize!
