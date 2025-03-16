# API Reference

1. **Ping the API**

   - Endpoint: `GET /api/ping`
   - Payload: None
   - Response Example
     ```json
     {
       "data": "pong"
     }
     ```
2. **Redirect by Slug**

   - Endpoint: `GET /:slug`
   - Payload: None
   - Response: 301

3. **List All Links**

   - Endpoint: `GET /api/links`
   - Headers: `X-Api-Key`
   - Query Parameters:
     - `limit` (optional): Number of results per page (default: 100)
     - `cursor` (optional): Pagination cursor from previous response
   - Response Example
     ```json
     {
       "data": [
         {
           "id": "84f0c7a4-8c4e-4665-b676-cb9c5e40f1db",
           "refer": "http://localhost:4000/3wP4BQ",
           "origin": "https://monocuco.donado.co"
         }
       ],
       "pagination": {
         "has_more": true,
         "next": "75e0a7f4-9c5e-1235-b546-eb9c5e40f7ac"
       }
     }
     ```

4. **List link by ID**
   - Endpoint: `GET /api/links/:id`
   - Headers: `X-Api-Key`
   - Payload: None
   - Note: This endpoint returns up to 100 of the most recent clicks. For complete click history, use the `/api/links/:id/clicks` endpoint with pagination.
   - Response Example
     ```json
     {
       "data": {
         "id": "84f0c7a4-8c4e-4665-b676-cb9c5e40f1db",
         "refer": "http://localhost:4000/3wP4BQ",
         "origin": "https://monocuco.donado.co",
         "clicks": [
           {
             "id": "730e2202-58f9-478c-a24c-f1c561df6716",
             "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:127.0) Gecko/20100101 Firefox/127.0",
             "country": "DE",
             "browser": "Firefox",
             "os": "Mac OS X",
             "referer": "Direct",
             "created_at": "2024-07-12T19:25:22Z"
           }
         ]
       }
     }
     ```

5. **List Clicks for a Link**
   - Endpoint: `GET /api/links/:id/clicks`
   - Headers: `X-Api-Key`
   - Query Parameters:
     - `limit` (optional): Number of results per page (default: 100)
     - `cursor` (optional): Pagination cursor from previous response
   - Response Example
     ```json
     {
       "data": [
         {
           "id": "730e2202-58f9-478c-a24c-f1c561df6716",
           "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:127.0) Gecko/20100101 Firefox/127.0",
           "country": "DE",
           "browser": "Firefox",
           "os": "Mac OS X",
           "referer": "Direct",
           "created_at": "2024-07-12T19:25:22Z"
         }
       ],
       "pagination": {
         "has_more": true,
         "next": "629e3301-47f8-389b-b24c-f1c561df9825"
       }
     }
     ```

6. **Create new link**
   - Endpoint: `POST /api/links`
   - Payload:
     ```json
     {
       "url": "https://example.com"
     }
     ```
   - Headers: `X-Api-Key`
   - Response Example:
     ```json
     {
       "data": {
         "id": "84f0c7a4-8c4e-4665-b676-cb9c5e40f1db",
         "refer": "http://localhost:4000/3wP4BQ",
         "origin": "https://example.com",
         "clicks": []
       }
     }
     ```

7. **Update an existing link by ID**
   - Endpoint: `PUT /api/links/:id`
   - Payload:
     ```json
     {
       "url": "https://newexample.com"
     }
     ```
   - Headers: `X-Api-Key`
   - Response Example:
     ```json
     {
       "data": {
         "id": "84f0c7a4-8c4e-4665-b676-cb9c5e40f1db",
         "refer": "http://localhost:4000/3wP4BQ",
         "origin": "https://newexample.com",
         "clicks": []
       }
     }
     ```

8. **Delete a link by ID**
  - Endpoint: `DELETE /api/links/:id`
  - Payload: None
  - Headers: `X-Api-Key`
  - Response: 204
