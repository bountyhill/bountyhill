# Be sure to restart your server when you modify this file.

Bountyhill::Application.config.session_store :cookie_store, 
                                        key: '_bh_session',
                                        expire_after: 30.days,
                                        secret: "d888d6186479178220cfbd2fccc4b411"

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rails generate session_migration")
# Bountyhill::Application.config.session_store :active_record_store
