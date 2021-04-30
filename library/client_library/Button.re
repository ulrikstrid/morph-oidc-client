open Tyxml;

module Link = {
  let createElement = (~href, ~title, ~children, ()) => {
    <a
      className="my-2 w-64 bg-transparent hover:bg-blue-500 text-blue-700 font-semibold hover:text-white py-2 px-4 border border-blue-500 hover:border-transparent rounded inline-flex items-center"
      href
      title>
      ...children
    </a>;
  };
};
