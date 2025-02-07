# API Reference

1. **Ping the API**

   - Endpoint: `GET /api/ping`
   - Payload: None
   - Response Example
     ```json
     {
       "message": "pong"
     }
     ```

2. **Redirect by Slug**

   - Endpoint: `GET /:slug`
   - Headers: `X-Api-Key`
   - Payload: None
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
             "language": "en-US",
             "browser": "Firefox",
             "os": "Mac OS X",
             "source": "Unknown",
             "created_at": "2024-07-12T19:25:22Z"
           }
         ]
       }
     }
     ```

3. **List All Links**

   - Endpoint: `GET /api/links`
   - Headers: `X-Api-Key`
   - Payload: None
   - Response Example
     ```json
     {
       "data": [
         {
           "id": "84f0c7a4-8c4e-4665-b676-cb9c5e40f1db",
           "refer": "http://localhost:4000/3wP4BQ",
           "origin": "https://monocuco.donado.co",
           "clicks": [
             {
               "id": "730e2202-58f9-478c-a24c-f1c561df6716",
               "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:127.0) Gecko/20100101 Firefox/127.0",
               "language": "en-US",
               "browser": "Firefox",
               "os": "Mac OS X",
               "source": "Unknown",
               "created_at": "2024-07-12T19:25:22Z"
             }
           ]
         }
       ]
     }
     ```

4. **List link by ID**

   - Endpoint: `GET /api/links/:id`
   - Headers: `X-Api-Key`
   - Payload: None
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
             "language": "en-US",
             "browser": "Firefox",
             "os": "Mac OS X",
             "source": "Unknown",
             "created_at": "2024-07-12T19:25:22Z"
           }
         ]
       }
     }
     ```

5. **Create new link**

   - Endpoint\*\*: `POST /api/links`
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
         "origin": "https://monocuco.donado.co/test",
         "clicks": []
       }
     }
     ```

6. **Update an existing link by ID**

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

7. **Delete a link by ID**

   - Endpoint: `DELETE /api/links/:id`
   - Payload: None
   - Headers: `X-Api-Key`
   - Response Example:
     ```json
     {
       "message": "Link deleted"
     }
     ```

