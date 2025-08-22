# README
Written in Ruby 3.4.5 and Rails 8.0.2.

# Setup:
1. Create an empty .env file to store environment variables.
2. Add in the export path variable - EXPORT_PATH=event_data (this export path can be changed according to your needs)
3. Create a google cloud application with the following scopes:
* https://www.googleapis.com/auth/userinfo.email
* https://www.googleapis.com/auth/userinfo.profile
* https://www.googleapis.com/auth/calendar.readonly
3. If publishing status of the google cloud app is 'Testing', be sure to add test user emails.
4. Save the client id and client secret from the google cloud app and put them into the .env file as variables.
* GOOGLE_CLIENT_ID=********
* GOOGLE_CLIENT_SECRET=*********
5. Create a microsoft azure application with the following scopes:
* email
* openid
* User.Read
* Calendars.Read
* offline_access
6. Save the client id and client secret from the microsoft azure app and put them into the .env file as variables.
* AZURE_CLIENT_ID=***************
* AZURE_CLIENT_SECRET=*************
  

# Local Server Running
1. Open up the directory: cd your_path/Calendar-Sync-Prototype.
2. Run rails s to start server
3. Go to http://localhost:3000/ on any web browser.
