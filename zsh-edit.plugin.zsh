#!/bin/zsh
setopt autopushd pushdminus
zmodload zsh/complist

zsh-edit() {
  emulate -L zsh
  typeset -gHa _edit_opts=( extendedglob NO_listbeep NO_shortloops warncreateglobal )
  setopt $_edit_opts

  local widget dir=${${(%):-%x}:P:h}
  local fdir=$dir/functions
  typeset -gU FPATH fpath=( $dir $fpath )
  autoload -Uz $fdir/bind $fdir/[._]edit.*~*.zwc(DN)

  .edit.bind() {
    local widget=$1
    shift
    bindkey -M emacs "$1" "$widget"
    bindkey "${@:^^widget}"
    widget=.$widget
    bindkey -M menuselect "${@:^^widget}"
  }

  local -a          left=(  '^['{\[,O}D )
  local -a    shift_left=(  '^['{'[1;',\[,O}2D )
  local -a      alt_left=(  '^['{'[1;',\[,O}3D '^[^['{\[,O}D )
  local -a     ctrl_left=(  '^['{'[1;',\[,O}5D )
  local -a alt_ctrl_left=(  '^['{'[1;',\[,O}7D '^[^['{'[1;',\[,O}5D )
  local -a          right=( '^['{\[,O}C )
  local -a    shift_right=( '^['{'[1;',\[,O}2C )
  local -a      alt_right=( '^['{'[1;',\[,O}3C '^[^['{\[,O}C )
  local -a     ctrl_right=( '^['{'[1;',\[,O}5C )
  local -a alt_ctrl_right=( '^['{'[1;',\[,O}7C '^[^['{'[1;',\[,O}5C )
  local -a page_up=(   '^[[5~' )
  local -a page_down=( '^[[6~' )
  local -a home=( '^['{\[,O}H )
  local -a  end=( '^['{\[,O}F )
  local backspace='^?'
  local -a      shift_backspace=( '^[[27;2;8~' )
  local -a        alt_backspace=( '^[[27;3;8~' '^[^?' )
  local -a       ctrl_backspace=( '^[[27;5;8~'   '^H' )
  local -a shift_ctrl_backspace=( '^[[27;6;8~' )
  local -a   alt_ctrl_backspace=( '^[[27;7;8~' '^[^H' )
  local delete='^[[3~'
  local -a      shift_delete=( '^[[3;2~' '^[^[[3~'    '^[(' )
  local -a        alt_delete=( '^[[3;3~' '^[^[[3~'    '^[(' )
  local -a       ctrl_delete=( '^[[3;5~' )
  local -a shift_ctrl_delete=( '^[[3;6~' )
  local -a   alt_ctrl_delete=( '^[[3;7~' '^[^[[3;5~' )


  for widget in {{back,for}ward,{backward-,}kill}-{sub,shell-}word; do
    zle -N "$widget" .edit.subword
  done

  bindkey "$backspace"  backward-delete-char
  bindkey "$delete"     delete-char
  .edit.bind backward-subword         '^[^B'  "$ctrl_left[@]"   "$alt_ctrl_left[@]"
  .edit.bind forward-subword          '^[^F'  "$ctrl_right[@]"  "$alt_ctrl_right[@]"
  .edit.bind backward-shell-word      '^[b'   "$alt_left[@]"    "$shift_left[@]"
  .edit.bind forward-shell-word       '^[f'   "$alt_right[@]"   "$shift_right[@]"
  .edit.bind beginning-of-line        '^A'    "$home[@]"        '^X'"$^left[@]"
  .edit.bind       end-of-line        '^E'    "$end[@]"         '^X'"$^right[@]"
  .edit.bind backward-kill-subword    '^H'    "$ctrl_backspace[@]"  "$alt_ctrl_backspace[@]"
  .edit.bind kill-subword             '^[^D'  "$ctrl_delete[@]"     "$alt_ctrl_delete[@]"
  .edit.bind backward-kill-shell-word '^W'    "$alt_backspace[@]"   "$shift_backspace[@]"
  .edit.bind kill-shell-word          '^[d'   "$alt_delete[@]"      "$shift_backspace[@]"
  .edit.bind backward-kill-line       '^U'    "$shift_ctrl_backspace[@]"  '^X'"$backspace"
  .edit.bind          kill-line       '^K'    "$shift_ctrl_delete[@]"     '^X'"$delete"

  # TODO: Let 'expand-history' do autocorrection from history when there's no history expansion on the line.
  # TODO: Search only through the last ~512 $historywords to prevent Zsh from crashing.
  zle -N {,.edit.}expand-history
  .edit.expand-history () {
    zle .expand-history || zle spell-word # || TODO: matching history line
  }

  .beginning-of-buffer() { CURSOR=0 }
        .end-of-buffer() { CURSOR=$#BUFFER }
  zle -N {,.}beginning-of-buffer
  zle -N {,.}end-of-buffer
  .edit.bind beginning-of-buffer  '^[<'   "$page_up[@]"     '^X'"$^up[@]"
  .edit.bind       end-of-buffer  '^[>'   "$page_down[@]"   '^X'"$^down[@]"

  unfunction .edit.bind

  [[ -v ZSH_AUTOSUGGEST_PARTIAL_ACCEPT_WIDGETS ]] ||
     typeset -gHa ZSH_AUTOSUGGEST_PARTIAL_ACCEPT_WIDGETS=()
  ZSH_AUTOSUGGEST_PARTIAL_ACCEPT_WIDGETS+=(
      end-of-line
      forward-{shell-,sub}word
  )

  zle -N find-replace-char    .edit.find-replace
  zle -N find-replace-pattern .edit.find-replace
  bindkey -M emacs  '^]'    find-replace-char
  # bindkey -M emacs  '^[^]'  find-replace-pattern

  for widget in yank yank-pop reverse-yank-pop vi-put-before vi-put-after; do
    zle -N $widget .edit.visual-yank
  done
  bindkey -M emacs  '^[/' redo \
                    '^[Y' reverse-yank-pop

  for widget in {insert-{last,first},copy-{prev,next}}-word; do
    zle -N "$widget" .edit.insert-word
  done
  bindkey -M emacs  '^[.'  insert-last-word \
                    '^[,'  insert-first-word \
                    '^[^_' copy-prev-word \
                    '^[_'  copy-next-word

  zle -N dirstack-minus .edit.dirstack
  zle -N dirstack-plus  .edit.dirstack
  bindkey -M emacs          '^[`' dirstack-minus \
                            '^[~' dirstack-plus
  bindkey -M menuselect -s  '^[`' '^G^_^[_' \
                            '^[~' '^G^_^[+'

  bind    -M emacs      '^[:' 'cd ..'

  bind    -M emacs      '^[-' 'pushd -1' \
                        '^[=' 'pushd +0'
  bindkey -M menuselect '^[-' menu-complete \
                        '^[=' reverse-menu-complete
}

{
  zsh-edit "$@"
} always {
  unfunction zsh-edit
}
