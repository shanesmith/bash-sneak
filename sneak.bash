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
  [[ "${#prompt}" -gt 0 ]] && tput cuf "${#prompt}"

  # move cursor to current point
  [[ "$READLINE_POINT" -gt 0 ]] && tput cuf "$READLINE_POINT"

  while true; do

    # read a single key
    read -rs -n1 key

    if [[ $? -ne 0 ]]; then
      # something went wrong
      return
    fi

    case "$key" in
      $'\e')
        # escape quits
        search=""
        break
        ;;

      $binding_char)
        # doubling binding char redoes last search
        search="${__sneak_last_search}"
        break
        ;;

      "")
        # ENTER does search with what we've got so far
        break
        ;;

      [[:print:]])
        # only accept printable characters
        search="$search$key"
        ;;
    esac;

    if [[ "${#search}" -eq "${num_chars}" ]]; then
      # we've got what we asked for, let's get down to business
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

  # save search
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
          pos = 0
          str = substr($0, 0, point + 1)
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
  # extract the letter (ie: "x" from "\C-x")
  # get ASCII decimal code
  # compute ASCII for for Ctrl-x
  # convert to octal number
  # print control character
  # ...there's got to be a saner way...
    bind -X \
      | awk -v direction="$1" '$0 ~ "__sneak_"direction { if ($1 ~ /^"\\C-[a-z]"/) printf "%s", substr($1, 5, 1) }' \
      | od -An -d \
      | xargs -I'{}' expr '{}' - 96 \
      | xargs printf "%o" \
      | xargs -I'{}' printf "%b" "\0{}"
}

__sneak_forward() {
  __sneak "forward"
}

__sneak_backward() {
  __sneak "backward"
}

bind -x "\"${SNEAK_BINDING_FORWARD-\C-g}\": __sneak_forward"

bind -x "\"${SNEAK_BINDING_BACKWARD-\C-t}\": __sneak_backward"

