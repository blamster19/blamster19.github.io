#/bin/bash

# This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

# You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.

site_url="https://blamster19.net"
update_date=$1

parse_body() {
  # after second `---`
  awk '/---/ {c++; next} c>1' $1 |
    # footnotes parsing
    sed -E '
			s/^\[\^([^][]+)\]:[[:space:]]*/<br \/><a id="fn\1" href="#ref\1"><sup>\1<\/sup><\/a> /
			s/\[\^([^][]+)\][[:space:]]*/<a href="#fn\1" id="ref\1"><sup>\1<\/sup><\/a> /g' | md2html --github -x |
    # add id for toc linking
    perl -pe 's{<h1>([^<]+)</h1>}{
			$t = $1;
			$id = lc($t);
			$id =~ s/[^a-z0-9]+/-/g;
			$id =~ s/^-+|-+$//g;
			"<h1 id=\"$id\">$t</h1>"}ge' |
    # remove image CSS parameters from legacy posts
    sed -E 's/(<img[^>]*>)\s*\{:[^}]*\}/\1/g'
}

print_entries() {
  cd ./_posts/
  local files=($(grep -l '^date: ' * | while read -r file; do
    local date=$(grep '^date: ' "$file" | cut -d' ' -f2)
    printf "%s\n" "$file"
  done | sort -n | cut -f2-))
  for ((i = ${#files[@]} - 1; i >= 0; i--)); do
    local post_file="${files[i]}"
    local date_published=$(grep '^date: ' "$post_file" | cut -d' ' -f2- | date -f - -Iseconds)
    local date_modified=$(date -u -r $post_file +"%Y-%m-%dT%H:%M:%S+00:00")
    local title=$(grep '^title: ' "$post_file" | cut -d' ' -f2- | sed 's/^[[:space:]]*//')
    local excerpt=$(grep '^excerpt: ' "$post_file" | cut -d' ' -f2-)
    local url="$site_url/$(
      printf "%s" "$post_file" |
        sed 's/^\(.\{4\}\)./\1\//;
        s/^\(.\{7\}\)./\1\//;
        s/^\(.\{10\}\)./\1\//;
        s/\.markdown/\.html/'
    )"
    local contents=$(parse_body <"$post_file")

    echo "<entry>"
    echo "  <title type=\"html\">$title</title>"
    echo "  <link href=\"$url\" rel=\"alternate\" type=\"text/html\" title=\"$title\"/>"
    echo "  <published>$date_published</published>"
    echo "  <updated>$date_modified</updated>"
    echo "  <id>$url</id>"
    echo "  <content type=\"html\" xml:base=\"$url\">"
    echo $contents
    echo "  </content>"
    echo "  <author>"
    echo "    <name>blamster19</name>"
    echo "  </author>"
    echo "  <summary type=\"html\">$excerpt</summary>"
    echo "</entry>"
  done
  cd ..

}

feed() {
  echo "<?xml version=\"1.0\" encoding=\"utf-8\"?>"
  echo "<feed xmlns=\"http://www.w3.org/2005/Atom\" >"
  echo "<generator version=\"1.0\">blampub</generator>"
  echo "<link href=\"$site_url/feed.xml\" rel=\"self\" type=\"application/atom+xml\" />"
  echo "<link href=\"$site_url/\" rel=\"alternate\" type=\"text/html\"/>"
  echo "<updated>$update_date</updated>"
  echo "<id>$site_url/feed.xml</id>"
  echo "<title type=\"html\">blamster19 - all stuff blamster</title>"
  echo "<subtitle>blamster19's little corner of the Net.</subtitle>"
  print_entries
  echo "</feed>"

}

feed
