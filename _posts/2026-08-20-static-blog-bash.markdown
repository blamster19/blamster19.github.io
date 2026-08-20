---
layout: post
title:  Static blog generation with Bash
date:   2026-08-20 14:30:00 +0200
categories:
tags: crafts electronics
excerpt: I migrated my blog to a custom Bash site generator
---

# What's wrong with normal SSGs?

When I created this blog (2023) I used [Jekyll Static Site Generator](https://jekyllrb.com/) (SSG) to produce HTML from Markdown files. You write the post in plain Markdown and the engine compiles it into a beautiful page with header and footer, pretty simple. I used GitHub Action to compile the site on every pushed commit.

Over time I've noticed several things that annoyed me so bad that I started to seek an alternative:

* the site source was unintelligible to me - I like to know how stuff works and I love to learn by example, but the SSG output is very obtuse and optimized for SEO and whatnot, which makes for an awful learning experience
* I got interested in Small Web/[IndieWeb](https://indieweb.org/)/[smolweb](https://smolweb.org/) and my blog did not live up to that standard (more on that later)
* GitHub changed the tools often enough that publishing every new post meant tweaking the Action configuration and upgrading Jekyll; things often broke and I had to do a few tries to get my site up
* My site was not flexible enough for me; it might be due to my lack of knowledge about the tool I was using, but I didn't want to spend time learning a tool that I would use a couple times a year if my knowledge would become obsolete after a few uses when new version changes everything

Other than that, I had a few other goals I wanted to accomplish:

* learn Bash - although I daily drive GNU/Linux systems for more than 6 years I've never really had much use for classic tools like `sed`, `awk` or even `grep`; I wanted a fun challenge and rewriting my blog in Bash was an excellent choice
* I wanted a system that will last - \*nix shell environment is so stable that my generator will work in 2, 5 or even 10 years (probably with minor tweaks)
* the source will be human-readable - manually crafted HTML and CSS is always nice to look at
* I wanted to reactivate my blog and be more active - hopefully I will have more time to do cool stuff and write about it
* I also have something big to write about, but I won't spoil it now
* I will be migrating from GitHub and will probably buy a proper domain; I've been using Codeberg for my private repositories for a year now and I'm ready to jump the ship

# Blog page structure

## Header and footer

The first stage of rewriting the static site generator is the creation of header and footer. The content, written in Markdown and converted to (X)HTML, sits between those. Building the page comes down to essentially one command:

```bash
cat header.html content.html footer.html
```

I wrote a new header and footer to match my old layout, wrote a CSS stylesheet to make my site pretty and then wrote the parsing part. When I was writing the HTML I tried to follow the rules laid out in the [smolweb guidelines](https://smolweb.org/guidelines.html). I don't think I followed them very faithfully, but I hope I managed to produce something accessible that degrades gracefully. Browsing the page in [Lynx](https://lynx.invisible-island.net/) works well enough.

## Body

Processing the content was fun. I decided to use [`md2html`](https://packages.debian.org/trixie/md2html) utility available in Debian repos as a starting point. I could have written the parser myself in Bash, but I wanted to allocate finite time to the project and parsing Markdown was not a priority. Still, the output of that tool had to be sanitized.
My posts were originally written for Jekyll, so they contain the Yaml front-matter with page data at the beginning of the file. I had to parse it separately from the proper body and extract the title, type and creation date.
Figuring out how to make the converted output work in the context of the whole page was fun. This is the pipeline that I made:

```bash
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
```

The first part of this pipeline takes only the parts of Markdown file that are after the second occurence of `---` string which is the closing delimiter of the front-matter. Next, I parse the Markdown footnotes to HTML because the version of `md2HTML` in the current Debian version (*Trixie*) ships without that capability (this part of the script will be obsolete in the future). I pass the result to `md2html` with flags `--github -x`. The first flag uses the GitHub flavor of Markdown (I had some strike-throughs `~~text~~` in my legacy pages) and the second flag forces the tool to generate XHTML. It's good because then all the tags are closed, it makes it easier to troubleshoot any errors. Next `sed` lowers the heading levels by one - this is because the Markdown files start with the highest heading `# h1` that is converted to `<h1></h1>`, which is good for direct conversion, but for me the parsed HTML is only a part of a bigger site. In my site the `<h1>` tags are reserved for the post title generated from the front-matter, and the post headings should be below it. Notice that I go from the smallest to the largest heading, otherwise all the headings would be converted to `<h6>` if the script lines would be executed in reverse order. Also, I do not convert `<h1>` to `<h2>` just yet. I do that in the next step with `perl`. Why? Because The top headings will be included in the Table of Contents! I convert `<h2>Heading Title</h2>` into `<h2 id="heading-title">Heading Title</h2>`. The last step is the deletion of `{: width="500" .center-image}` or something like that that was appended after image embedding in legacy post. Inspired by the tenets of smolweb I decided to simplify my page and not style the images individually.\\
I generate the HTML ToC, the title and publishing and modification dates and combine all that to create the content body.

If the layout of the page in the front-matter says `"home"`, then it is the index page that lists all the blog posts. To list all posts with their titles, dates and excerpts I do the following:

```bash
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

```

This goes through all the posts in creation chronological order and writes the titles, UTC dates and excerpts.

## Compilation

The script I wrote compiles a single site. My blog is of course composed of many files and not all of them need to be compiled every time I change something. The obvious choice of a tool to conditionally compile changed files was `make`. This was the most tedious and time-consuming part of my project because I cannot write Makefiles for the life of me. I managed to make something like this:

```bash
PAGES_SRC := pages-md
POSTS_SRC := _posts
HTML_OUT := html

PAGES_MD := $(wildcard $(PAGES_SRC)/*.markdown)
POSTS_MD := $(wildcard $(POSTS_SRC)/*.markdown)

PAGES_HTML := $(patsubst $(PAGES_SRC)/%.markdown,$(HTML_OUT)/%.html,$(PAGES_MD))
POSTS_HTML := $(foreach f,$(POSTS_MD),$(HTML_OUT)/$(shell echo $(notdir $(f)) | sed -E 's/^([0-9]{4})-([0-9]{2})-([0-9]{2})-(.*)\.markdown$$/\1\/\2\/\3\/\4.html/'))
POSTS_HTML_DIRS := $(foreach f,$(POSTS_MD),$(HTML_OUT)/$(shell echo $(notdir $(f)) | sed -E 's/^([0-9]{4})-([0-9]{2})-([0-9]{2})-(.*)\.markdown$$/\1\/\2\/\3/'))

define post_rule
$(HTML_OUT)/$(shell echo $(notdir $(1)) | sed -E 's/^([0-9]{4})-([0-9]{2})-([0-9]{2})-(.*)\.markdown$$/\1\/\2\/\3\/\4.html/'): $(1) | $(HTML_OUT)/$(shell echo $(notdir $(1)) | sed -E 's/^([0-9]{4})-([0-9]{2})-([0-9]{2})-(.*)\.markdown$$/\1\/\2\/\3/')
 /bin/bash ./blampub.sh $$< > $$@
endef

all: $(PAGES_HTML) $(POSTS_HTML) $(HTML_OUT)/feed.xml

$(HTML_OUT)/%.html: $(PAGES_SRC)/%.markdown
 /bin/bash ./blampub.sh $< > $@

$(foreach f,$(POSTS_MD),$(eval $(call post_rule,$(f))))

$(POSTS_MD): | $(POSTS_HTML_DIRS)

$(POSTS_HTML_DIRS):
 mkdir -p $@

$(HTML_OUT)/feed.xml:
 /bin/bash ./feedgen.sh > $@

clean:
 find $(HTML_OUT)/ -mindepth 1 -not -path '*/assets*' -delete
```

The main complication was the handling of post files names. Each markdown source file has a name like `yyyy-mm-dd-arbitrary-post-title.markdown`. The output page is stored in `yyyy/mm/dd/arbitrary-post-title.html`. I needed to extract the date from the filename, create the proper directory structure and preserve the rest of the filename. The fact that the name could contain hyphens complicated the matter, because I could not simply turn every `-` into `/` and have the path for free. This is why I need the lengthy `post_rule` that generates appropriate rule for every source file that exists in the `foreach` loop.

## Feed

The Atom feed was trivial to implement. It is mostly `echo`ing the XML boilerplate and the parsed Markdown file. This time I do not lower the heading levels. I reused the code for parsing and listing posts in chronological order.

# Outcome

The result I got is a nice, understandable static site generator that I hope will serve me well. I learned a bit of Bash in the process which is what I wanted. In the process of migrating to the new generator I had to upgrade some posts to remove MathJax script CDN linking. Now I use a minimal installation of [Temml](https://temml.org/) that sits in the website assets and is loaded in the browser to turn every `$$text$$` into LaTeX math.

