open Opium_misc
open Opium_rock

let exn_ e = Lwt_log.ign_error_f "%s" (Printexc.to_string e)

let format_error req _exn = Printf.sprintf "
<html>
  <body>
  <div id=\"request\"><pre>%s</pre></div>
  <div id=\"error\"><pre>%s</pre></div>
  </body>
</html>" (req |> Request.sexp_of_t |> Sexplib.Sexp.to_string_hum) (Printexc.to_string _exn)

let debug =
  let filter handler req =
    Lwt.catch (fun () -> handler req) (fun _exn ->
      exn_ _exn;
      let body = format_error req _exn in
      Response.of_string_body ~code:`Internal_server_error body |> return)
  in Middleware.create ~name:"Debug" ~filter

let trace =
  let filter handler req =
    handler req >>| fun response ->
    let code = response |> Response.code |> Cohttp.Code.code_of_status in
    Lwt_log.ign_debug_f "Responded with %d" code;
    response
  in Middleware.create ~name:"Trace" ~filter
