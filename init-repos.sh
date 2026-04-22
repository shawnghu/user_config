# su root
# need -A
# git clone git@github.com:shawnghu/user_config.git
# cd user_config
# ./install.sh
set -e
"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/sync_server/pull.sh"
ssh-keyscan -H github.com >> ~/.ssh/known_hosts
cd
git clone git@github.com:shawnghu/small-rl.git
git clone git@github.com:ariahw/rl-rewardhacking-private.git
cd rl-rewardhacking-private/
source commands.sh 
create_leetcode_dataset "simple_overwrite_tests"
create_leetcode_dataset "simple_overwrite_tests_aware"
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
uv run python tools/generate_conditional_leetcode_data.py --unhinted_frac 0.5
