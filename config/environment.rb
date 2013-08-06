# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
Bountyhill::Application.initialize!

# Solve the file encoding problem
Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8