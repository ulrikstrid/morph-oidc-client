open Tyxml;

let createElement = (~title, ~children, ()) =>
  <div
    className="min-w-sm max-w-lg my-10 rounded overflow-hidden shadow-lg bg-white">
    <div className="px-6 py-4">
      <h1 className="font-bold text-2xl mb-2"> {Html.txt(title)} </h1>
    </div>
    <div
      className="px-6 py-4 flex content-center flex-wrap justify-center flex-col">
      ...children
    </div>
  </div>;
