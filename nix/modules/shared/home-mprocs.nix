{ ... }:

{
  xdg.configFile."mprocs/mprocs.yaml".text = ''
    # C-a clashes with zellij prefix. l/C-t instead of C-a for toggle-focus.
    keymap_procs:
      <C-a>: null
      <l>: { c: toggle-focus }
    keymap_term:
      <C-a>: null
      <C-t>: { c: toggle-focus }
  '';
}
