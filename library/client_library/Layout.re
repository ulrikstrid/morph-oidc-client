open Tyxml;

let createElement = (~title, ~children, ()) =>
  <html lang="en" className="text-gray-900 antialiased leading-tight">
    <head>
      <meta charset="utf-8" />
      <meta name="viewport" content="width=device-width, initial-scale=1" />
      <link
        href="https://unpkg.com/tailwindcss@1.4.5/dist/tailwind.min.css"
        rel="stylesheet"
      />
      <link
        rel="stylesheet"
        href="https://fonts.googleapis.com/icon?family=Material+Icons"
      />
      <title> {Html.txt(title)} </title>
    </head>
    <body className="min-h-screen bg-gray-300 text-gray-800 antialiased">
      <div className="container mx-auto"> ...children </div>
    </body>
  </html>;
