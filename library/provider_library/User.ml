type t = {
  full_name : string;
  first_name : string;
  last_name : string;
  email : string;
  password : string;
}

let users =
  [
    ( "ulrik.strid@outlook.com",
      {
        full_name = "Ulrik Strid";
        first_name = "Ulrik";
        last_name = "Strid";
        email = "ulrik.strid@outlook.com";
        password = "test";
      } );
  ]

let find_valid email password =
  let user = List.assoc email users in
  if user.password = password then Some user else None

let find email = List.assoc email users
