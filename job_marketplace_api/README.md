# JobMarketplaceApi

A robust API for a job marketplace, designed to connect job seekers with opportunities and to notify clients about new applications.

## Table of Contents

-   [Features](#features)
-   [Setup](#setup)
    -   [Prerequisites](#prerequisites)
    -   [Installation](#installation)
    -   [Environment Variables](#environment-variables)
    -   [Running the Application](#running-the-application)
-   [Usage / API Endpoints](#usage--api-endpoints)
    -   [Testing Real Email Notifications (Development)](#testing-real-email-notifications-development)
-   [Running Tests](#running-tests)
-   [Design Decisions & Tradeoffs](#design-decisions--tradeoffs)
-   [Future Improvements](#future-improvements)
-   [License](#license)

## Features

-   **Job Opportunity Management:** Enables the creation, listing, and general management of job opportunities.
-   **Client Management:** Handles client accounts, which are linked to specific job opportunities.
-   **Background Email Notifications:** Asynchronously notifies clients via email when a job seeker applies to one of their listed opportunities, utilizing Sidekiq for background processing and Action Mailer for email delivery.
-   **Redis Caching:** Incorporates Redis for caching frequently accessed data, which helps improve overall application performance.

## Setup

### Prerequisites

Before setting up the application, ensure you have the following installed:

-   **Ruby:** Version 3.2.2
-   **Rails:** Version 7.1.5.1
-   **PostgreSQL:**
-   **Redis:** Required for Sidekiq and caching

### Installation

1.  **Clone the repository:**
    ```bash
    git clone [https://github.com/jturgeon88/job-marketplace-api.git](https://github.com/jturgeon88/job-marketplace-api.git)
    cd job-marketplace-api
    ```

2.  **Install Ruby dependencies:**
    ```bash
    bundle install
    ```

3.  **Set up the database:**
    ```bash
    rails db:create
    rails db:migrate
    rails db:seed
    ```

### Environment Variables

The application relies on environment variables for sensitive credentials and configuration. It is recommended to use a tool like `dotenv-rails` for local development (though not explicitly added to your Gemfile yet, it's a common practice), or set these variables directly in your shell environment. Ensure these variables are not committed to version control (e.g., by adding `.env` to your `.gitignore`).

**Required Variables:**

| Variable             | Description                                                                                                                                                                                                                                           | Example Value                      |
| :------------------- | :---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :--------------------------------- |
| `DATABASE_URL`       | The connection string for your PostgreSQL database.                                                                                                                                                                                                   | `postgresql://localhost/job_marketplace_dev` |
| `REDIS_URL_SIDEKIQ`  | The URL for the Redis server specifically used by Sidekiq.                                                                                                                                                                                            | `redis://localhost:6379/2`           |
| `REDIS_URL_CACHE`    | The URL for the Redis server used for caching. This can be the same as `REDIS_URL_SIDEKIQ` but is often separated in production for better resource management.                                                                                     | `redis://localhost:6379/1`           |
| `GMAIL_USERNAME`     | The Gmail email address from which notification emails will be sent. If two-factor authentication (2FA) is enabled for this Gmail account, an App Password must be used.                                                                             | `your_email@gmail.com`             |
| `GMAIL_APP_PASSWORD` | The **App Password** generated for the `GMAIL_USERNAME` account. This is essential when 2FA is enabled. Do not use your regular Google account password. If 2FA is off, you might need to enable "less secure app access" (though this is not recommended). | `abcd efgh ijkl mnop`              |

**Example of setting environment variables in your terminal (for a single session):**

```bash
export DATABASE_URL="postgresql://localhost/job_marketplace_dev"
export REDIS_URL_SIDEKIQ="redis://localhost:6379/2"
export REDIS_URL_CACHE="redis://localhost:6379/1"
export GMAIL_USERNAME="your_email@gmail.com"
export GMAIL_APP_PASSWORD="your_16_character_app_password"
```

## Running the Application

To run the application, you need to start both the Rails server and the Sidekiq worker process.

### Start the Rails Server

Open your first terminal window, ensure the environment variables are set (as shown above), and run:

    ```bash
    rails s
    ```

### Start the Sidekiq Worker

Open a new terminal window/tab, ensure the environment variables are also set in this session, and run:

    ```bash
    bundle exec sidekiq -C config/sidekiq.yml
    ```

The API will typically be accessible at http://localhost:3000

---

## Usage / API Endpoints

Once the application is running, you can interact with it using its defined API endpoints.

### Example: Applying to an Opportunity (Triggers Email Notification)

To test the email notification functionality, ensure you have existing `Opportunity` and `JobSeeker` records in your development database. The associated `Client` must have a valid email address configured.

Example curl command:

    ```bash
    curl -X POST \
      http://localhost:3000/opportunities/<OPPORTUNITY_ID>/apply \
      -H 'Content-Type: application/json' \
      -d '{
        "application": {
          "job_seeker_id": <JOB_SEEKER_ID>
        }
      }'
    ```

Replace `<OPPORTUNITY_ID>` and `<JOB_SEEKER_ID>` with actual IDs. Upon successful submission, the client linked to the opportunity will receive an email notification.

---

## Testing Real Email Notifications (Development)

### Set up a Gmail App Password (if using 2FA)

If your `GMAIL_USERNAME` has 2FA enabled (recommended), generate an App Password:

1. Go to https://myaccount.google.com
2. Navigate to Security → How you sign in to Google → App passwords
3. Follow instructions to generate a 16-character password
4. Use this for `GMAIL_APP_PASSWORD`

### Set Environment Variables

Ensure both `GMAIL_USERNAME` and `GMAIL_APP_PASSWORD` are set in the terminal sessions running:

    ```bash
    rails s
    ```

and
    ```bash
    bundle exec sidekiq -C config/sidekiq.yml
    ```

### Trigger an Application via curl

Use the same curl command shown above, making sure the client’s email is accessible (e.g., your own).

### Check Email Inbox

After sending the curl request, the `ApplicationNotificationWorker` will process the email job. Check the inbox of the specified client. You should receive a “New Application for...” email.

You can also monitor:

- Sidekiq UI: http://localhost:3000/sidekiq
- Rails server logs

---

## Running Tests

To run the RSpec test suite:

    ```bash
    bundle exec rspec
    ```

To run tests for a specific file:

    ```bash
    bundle exec rspec spec/services/apply_to_opportunity_spec.rb
    ```

---

## Future Improvements

- Implement a **dedicated mailer queue** for better job prioritization.
- Add **robust error handling & retry logic** for email delivery.
- Set up **Action Mailer Previews** for easier development/testing of emails.
