declare __sneak_last_search

__sneak() {
  local search

  local direction="$1"

  local prompt="${SNEAK_PROMPT-/ }"

  local num_chars="${SNEAK_NUM_CHARS:-2}"

  local binding_char=$(__sneak_get_bind_char "$direction")

  # save cursor (col 0)
  tput sc

  # re-show the current line
  echo -n "${prompt}${READLINE_LINE}"

  # restore cursor (col 0)
  tput rc

  # move cursor forward past prompt
  if [[ "${#prompt}" -gt 0 ]]; then
    tput cuf ${#prompt}
  fi

  if [[ "$READLINE_POINT" -gt 0 ]]; then
    # move cursor to current point
    tput cuf $READLINE_POINT
  fi

  while true; do

    # read a single key
    read -rs -n1 key

    if [[ $? -ne 0 ]]; then
      return
    fi

    case "$key" in
      $'\e')
        search=""
        break
        ;;

      $binding_char)
        search="${__sneak_last_search}"
        break
        ;;

      "")
        break
        ;;

      [[:print:]])
        search="$search$key"
        ;;
    esac;

    if [[ "${#search}" -eq "${num_chars}" ]]; then
      break
    fi

  done

  # restore cursor (col 0)
  tput rc

  # erase line
  tput el

  if [[ -z "${search}" ]]; then
    return
  fi

  __sneak_last_search="${search}"

  READLINE_POINT=$(
    echo "$READLINE_LINE" | awk \
      -v point="$READLINE_POINT" \
      -v direction="$direction" \
      -v search="$search" \
      '{
        if (direction == "forward") {
          point += index(substr($0, point+2), search);
        }
        else {
          str = substr($0, 0, point + 1)
          pos = 0
          while (i = index(substr(str, pos+1), search)) {
            pos += i
          }
          if (pos != 0) point = pos - 1
        }

        print point
      }'
  )

}

__sneak_get_bind_char() {
  bind -X | awk -v direction="$1" '$0 ~ "__sneak_"direction { if ($1 ~ /^"\\C-[a-z]"/) printf "%s", substr($1, 5, 1) }' | od -An -d | xargs -I'{}' expr '{}' - 96 | xargs printf "%o" | xargs -I'{}' printf "%b" "\0{}"
}


__sneak_forward() {
  __sneak "forward"
}

__sneak_backward() {
  __sneak "backward"
}

bind -x "\"${SNEAK_BINDING_FORWARD-\C-y}\": __sneak_forward"

bind -x "\"${SNEAK_BINDING_BACKWARD-\C-t}\": __sneak_backward"

