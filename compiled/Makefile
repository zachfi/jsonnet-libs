# Compiled output and checks for jsonnet-libs.
#
# Multiple app samples: list envs in APP_ENVS; each compiled/<env>/ has main.jsonnet
# and output in compiled/<env>/gen/. Add a new directory and add its name to APP_ENVS
# to scale.
#
# Use from repo root: make -C compiled all
# Or from compiled/: make all (ROOT=..)
#
#   find compiled/ -name main.jsonnet
#   → compiled/app/main.jsonnet
#   → compiled/chrony/main.jsonnet
#
ROOT ?= ..
OUT_DIR ?= out
APP_ENVS ?= app chrony

# Only compiled/<env>/gen is committed and checked. out/ is local-only (jsonnetfile snapshot).
CHECK_GEN_DIRS := $(addprefix compiled/,$(addsuffix /gen,$(APP_ENVS)))
GEN_DIRS := $(addsuffix /gen,$(APP_ENVS))

.PHONY: all jb copy-jsonnetfile gen check check-examples clean

all: jb copy-jsonnetfile gen check

# Install deps at repo root; ensure same-repo import path (vendor/github.com/zachfi/jsonnet-libs).
jb:
	cd $(ROOT) && jb install
	@mkdir -p $(ROOT)/vendor/github.com/zachfi
	@rm -f $(ROOT)/vendor/github.com/zachfi/jsonnet-libs
	@ln -sfn $$(cd $(ROOT) && pwd) $(ROOT)/vendor/github.com/zachfi/jsonnet-libs

# Copy jsonnetfile*.json into test output dir for record/CI.
copy-jsonnetfile: $(OUT_DIR)
	cp $(ROOT)/jsonnetfile.json $(ROOT)/jsonnetfile.lock.json $(OUT_DIR)/

$(OUT_DIR):
	mkdir -p $(OUT_DIR)

# Generate each app env: export to temp dir, then copy *.yaml into compiled/<env>/gen/.
gen: jb copy-jsonnetfile
	@for env in $(APP_ENVS); do \
		(cd $(ROOT) && tk export $(CURDIR)/.tk-out-$$env compiled/$$env --merge-strategy=replace-envs && \
		rm -rf compiled/$$env/gen && mkdir -p compiled/$$env/gen && \
		cp compiled/.tk-out-$$env/*.yaml compiled/$$env/gen/ && \
		rm -rf compiled/.tk-out-$$env) || exit 1; \
	done

# Check only compiled/<env>/gen: (1) all generated files tracked and up to date,
# (2) deleted files removed from git, (3) any diff fails. Run git from repo root.
check: gen check-examples

check-examples:
	@cd $(ROOT) && git diff --exit-code -- $(CHECK_GEN_DIRS) || (echo "Error: uncommitted changes in compiled/*/gen. Commit updated output after 'make gen'."; exit 1)
	@cd $(ROOT) && if [ -n "$$(git ls-files --others --exclude-standard $(CHECK_GEN_DIRS))" ]; then \
		echo "Error: Untracked files in compiled/*/gen:"; \
		git ls-files --others --exclude-standard $(CHECK_GEN_DIRS); \
		echo ""; \
		echo "To make check pass, add and commit the generated files (from repo root):"; \
		echo "  git add $(CHECK_GEN_DIRS)"; \
		echo "  git commit -m 'chore: compiled jsonnet output'"; \
		exit 1; \
	fi

clean:
	rm -rf $(OUT_DIR) $(GEN_DIRS) $(addprefix .tk-out-,$(APP_ENVS))
