# su root
# need -A
# git clone git@github.com:shawnghu/user_config.git
# cd user_config
# ./install.sh
set -e
"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/sync_server/pull.sh"
ssh-keyscan -H github.com >> ~/.ssh/known_hosts
cd
[ -d small-rl ] || git clone git@github.com:shawnghu/small-rl.git
[ -d rl-rewardhacking-private ] || git clone git@github.com:ariahw/rl-rewardhacking-private.git
cd rl-rewardhacking-private/
source commands.sh
# `|| true`: create_leetcode_dataset raises "Dataset already exists" on re-runs,
# and we don't want that to abort the rest of the setup.
create_leetcode_dataset "simple_overwrite_tests" || true
create_leetcode_dataset "simple_overwrite_tests_aware" || true
cd
cd small-rl
# git checkout worktree-scale-up
[ -f ~/.secrets_env ] && source ~/.secrets_env
# Seed .env with whichever keys are populated. `|| true` guards against the
# subshell returning non-zero (and tripping `set -e`) when none of the vars are set.
(
    umask 077
    : > .env
    [ -n "$OPENAI_API_KEY" ] && echo "OPENAI_API_KEY=$OPENAI_API_KEY" >> .env
    [ -n "$JUDGE_API_KEY" ] && echo "JUDGE_API_KEY=$JUDGE_API_KEY" >> .env
    [ -n "$CLAUDE_CODE_OAUTH_TOKEN" ] && echo "CLAUDE_CODE_OAUTH_TOKEN=$CLAUDE_CODE_OAUTH_TOKEN" >> .env
    true
) || true
uv sync
source .venv/bin/activate
uv run ./vllm_patches/apply.sh
uv run ./setup_leetcode_eval_data.sh
uv run python tools/generate_conditional_leetcode_data.py --unhinted_frac 0.1
uv run python tools/generate_conditional_leetcode_data.py --unhinted_frac 0.2
uv run python tools/generate_conditional_leetcode_data.py --unhinted_frac 0.3
uv run python tools/generate_conditional_leetcode_data.py --unhinted_frac 0.4
uv run python tools/generate_conditional_leetcode_data.py --unhinted_frac 0.5
