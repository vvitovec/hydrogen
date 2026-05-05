import Foundation

enum StartPage {
    static let html = """
    <!doctype html>
    <html>
      <head>
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <style>
          html, body {
            margin: 0;
            height: 100%;
            font: -apple-system-body;
            background: #f7f7f4;
            color: #20211f;
          }
          main {
            min-height: 100%;
            display: grid;
            place-items: center;
            padding: 24px;
            box-sizing: border-box;
          }
          h1 {
            font-size: 28px;
            font-weight: 650;
            margin: 0 0 8px;
            letter-spacing: 0;
          }
          p {
            margin: 0;
            color: #676b62;
          }
        </style>
      </head>
      <body>
        <main>
          <section>
            <h1>Hydrogen</h1>
            <p>Search or enter a website above.</p>
          </section>
        </main>
      </body>
    </html>
    """
}
