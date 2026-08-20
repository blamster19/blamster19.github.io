#/bin/bash

# This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

# You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.

parse_front_matter() {
  while IFS= read -r line; do
    case $line in
    layout:*)
      layout=${line#layout: }
      ;;
    title:*)
      title=${line#title: }
      ;;
    date:*)
      date_stamp=${line#date: }
      ;;
    excerpt:*)
      excerpt=${line#excerpt: }
      ;;
    esac
  done < <(sed -n '/^---/,/^---/p' $1)
}

make_table_of_contents() {
  local input="${1:-/dev/stdin}"
  local toc=()
  while IFS= read -r line; do
    # if [[ $line == \#\ * ]]; then
    if [[ $line =~ ^\<h1\>(.*)\<\/h1\>$ ]]; then
      # local section=("${line#\#}")
      local section="${BASH_REMATCH[1]}"
      local slug=$(
        perl -ne 'chomp;
				$t=$_;
				$id=lc($t);
				$id=~s/[^a-z0-9]+/-/g;
				$id=~s/^-+|-+$//g;
				print $id' <<<"$section"
      )
      toc+=("<li><a href=\"#$slug\">$section</a>")
    fi
  done <"$input"
  printf '%s\n' "${toc[@]}"
}

parse_body() {
  # after second `---`
  awk '/---/ {c++; next} c>1' $1 |
    # footnotes parsing
    sed -E '
			s/^\[\^([^][]+)\]:[[:space:]]*/<br \/><a id="fn\1" href="#ref\1"><sup>\1<\/sup><\/a> /
			s/\[\^([^][]+)\][[:space:]]*/<a href="#fn\1" id="ref\1"><sup>\1<\/sup><\/a> /g' | md2html --github -x |
    # lower the headings
    sed \
      -e 's@<h5>@<h6>@g; s@</h5>@</h6>@g' \
      -e 's@<h4>@<h5>@g; s@</h4>@</h5>@g' \
      -e 's@<h3>@<h4>@g; s@</h3>@</h4>@g' \
      -e 's@<h2>@<h3>@g; s@</h2>@</h3>@g' |
    # lower h1 to h2 and add id for toc linking
    perl -pe 's{<h1>([^<]+)</h1>}{
			$t = $1;
			$id = lc($t);
			$id =~ s/[^a-z0-9]+/-/g;
			$id =~ s/^-+|-+$//g;
			"<h2 id=\"$id\">$t</h2>"}ge' |
    # remove image CSS parameters from legacy posts
    sed -E 's/(<img[^>]*>)\s*\{:[^}]*\}/\1/g'
}

list_posts() {
  echo "<h2>Posts</h2>"
  cd ./_posts/
  local files=($(grep -l '^date: ' * | while read -r file; do
    local date=$(grep '^date: ' "$file" | cut -d' ' -f2)
    printf "%s\n" "$file"
  done | sort -n | cut -f2-))
  for ((i = ${#files[@]} - 1; i >= 0; i--)); do
    local post_file="${files[i]}"
    local date_md=$(grep '^date: ' "$post_file" | cut -d' ' -f2-)
    local date_utc=$(date -u -d "$date_md" +"%Y-%m-%dT%H:%M:%SZ")
    local title=$(grep '^title: ' "$post_file" | cut -d' ' -f2-)
    local excerpt=$(grep '^excerpt: ' "$post_file" | cut -d' ' -f2-)
    local url=$(
      printf "%s" "$post_file" |
        sed 's/^\(.\{4\}\)./\1\//;
				s/^\(.\{7\}\)./\1\//;
				s/^\(.\{10\}\)./\1\//;
				s/\.markdown/\.html/'
    )
    echo "<a href="$url"><h3>$title</h3></a>"
    echo "<small>$date_utc</small><br />"
    echo "<p>$excerpt</p>"
  done
  cd ..
}

make_page_content() {
  local markdown_file=$1

  parse_front_matter $markdown_file
  # if exists
  if [ -n "$title" ]; then
    echo "<h1>$title</h1>"
  fi
  if [ -n "$date_stamp" ]; then
    local date_utc=$(date -u -d "$date_stamp" +"%Y-%m-%dT%H:%M:%SZ")
    echo "Published: $date_utc <br />"
    local date_modified=$(date -u -r $markdown_file +"%Y-%m-%dT%H:%M:%SZ")
    echo "Last modified: $date_modified <br />"
  fi
  if [ "$layout" == "post" ]; then
    echo "<h3>Contents</h3>"
    echo "<ol>"
    md2html --github -x $markdown_file | make_table_of_contents
    echo "</ol>"
  fi

  parse_body $markdown_file
  if [ "$layout" == "home" ]; then
    # show last posts
    list_posts
  fi
}

compose_header_content_footer() {
  local content=$(make_page_content $1)
  cat ./templates/header.html <(echo "$content") ./templates/footer.html
}

# parse_front_matter $1
# make_page_content $1
compose_header_content_footer $1
