(**

   This module implements workspace, an original string and a set of patches
   over it.

*)

type 'ctx t = {

  (* Original string value *)
  value : string;

  (* List of patches sorted in desceding order *)
  patches: 'ctx patch list;
}

and 'ctx patch = {

  (* Start offset into an original value *)
  offset_start : int;

  (* End offset into an original value *)
  offset_end : int;

  (* Patch to apply *)
  patch : 'ctx -> string;
}

let of_string s =
  { value = s; patches = []; }

let patch w p =
  { w with patches = p::w.patches }

let write out w ctx =
  let patches = List.rev w.patches in
  let rec write_patch offset value patches =
    match patches with
    | [] ->
      Lwt_io.write_from_exactly out value offset (String.length value - offset)
    | patch::patches ->
      let%lwt () = Lwt_io.write_from_exactly out value offset (patch.offset_start - offset) in
      let%lwt () = Lwt_io.write out (patch.patch ctx) in
      write_patch patch.offset_end value patches
  in
  write_patch 0 w.value patches

let to_string w ctx =
  let patches = List.rev w.patches in
  let rec print offset value patches =
    match patches with
    | [] ->
      String.sub value offset (String.length value - offset)
    | patch::patches ->
      let patch_pre = String.sub value offset (patch.offset_start - offset) in
      patch_pre ^ (patch.patch ctx) ^ (print patch.offset_end value patches)
  in
  print 0 w.value patches