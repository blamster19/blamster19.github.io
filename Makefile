PAGES_SRC := pages-md
POSTS_SRC := _posts
HTML_OUT := docs
INDEX_HTML := $(HTML_OUT)/index.html

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

$(HTML_OUT)/feed.xml: $(POSTS_MD)
	/bin/bash ./feedgen.sh "$(shell date -u +'%Y-%m-%dT%H:%M:%S.%3NZ')" > $@

$(INDEX_HTML): $(PAGES_SRC)/index.markdown $(POSTS_MD)
	/bin/bash ./blampub.sh $< > $@

clean:
	find $(HTML_OUT)/ -mindepth 1 -not -path '*/assets*' -delete

