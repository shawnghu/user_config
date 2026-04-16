# su root
# need -A
# git clone git@github.com:shawnghu/user_config.git 
# cd user_config
# ./install.sh
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
(umask 077 && {
    [ -n "$OPENAI_API_KEY" ] && echo "OPENAI_API_KEY=$OPENAI_API_KEY"
    [ -n "$CLAUDE_CODE_OAUTH_TOKEN" ] && echo "CLAUDE_CODE_OAUTH_TOKEN=$CLAUDE_CODE_OAUTH_TOKEN"
} > .env)
uv venv
source .venv/bin/activate
uv pip install -r pyproject.toml
uv run ./vllm_patches/apply.sh
uv run ./setup_leetcode_eval_data.sh
uv run python tools/generate_conditional_leetcode_data.py --unhinted_frac 0.5
