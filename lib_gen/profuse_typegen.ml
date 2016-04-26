(*
 * Copyright (c) 2015 David Sheets <sheets@alum.mit.edu>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 *)

open Ctypes

let fuse_version = ref ""
let output_file = ref "/dev/stdout"

let die fmt = Printf.kprintf (fun s -> prerr_string s; exit 1) fmt

let argspec : (Arg.key * Arg.spec * Arg.doc) list = [
  "--fuse-version", Arg.Set_string fuse_version, "FUSE version";
  "--output-file", Arg.Set_string output_file, "output file";
]

let fuse_versions : (string * (string * (module Cstubs.Types.BINDINGS))) list = [
  "7_8", ("fuse_kernel.h.7_8", (module Profuse_types_7_8.C));
  "7_9", ("fuse_kernel.h.7_9", (module Profuse_types_7_9.C));
  "7_10", ("fuse_kernel.h.7_10", (module Profuse_types_7_10.C));
]

let resolve_version : string -> (string * (module Cstubs.Types.BINDINGS)) =
  fun v ->
    try List.assoc v fuse_versions
    with Not_found ->
      die "Unsupported FUSE version: %s\nSupported versions: %s\n"
        v (String.concat ", " (List.map fst fuse_versions))

let () =
  let () = Arg.parse argspec failwith "" in
  if !fuse_version = "" then die "missing argument: --fuse-version"
  else
    let header, bindings_module = resolve_version !fuse_version in
    let type_oc = open_out !output_file in
    let fmt = Format.formatter_of_out_channel type_oc in
    Format.fprintf fmt "#include <stdint.h>@.";
    Format.fprintf fmt "#include \"%s\"@." header;
    Cstubs.Types.write_c fmt bindings_module;
    close_out type_oc;
