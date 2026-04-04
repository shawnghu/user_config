# su root
# need -A
# git clone git@github.com:shawnghu/user_config.git 
# cd user_config
# ./install.sh
ssh-keyscan -H github.com >> ~/.ssh/known_hosts
cd
git clone git@github.com:ariahw/rl-rewardhacking-private.git
cd rl-rewardhacking-private/
source commands.sh 
create_leetcode_dataset "simple_overwrite_tests"
create_leetcode_dataset "simple_overwrite_tests_aware"
cd
git clone git@github.com:shawnghu/small-rl.git
cd small-rl
git checkout worktree-scale-up
uv venv
source .venv/bin/activate
uv pip install -r pyproject.toml
uv run ./vllm_patches/apply.sh
