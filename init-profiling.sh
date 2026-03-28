# su root
# need -A
ssh-keyscan github.com >> ~/.ssh/known_hosts 2>/dev/null
git clone git@github.com:shawnghu/user_config.git
cd user_config
./install.sh
cd sync_server
./sync.sh &
cd
git clone git@github.com:ariahw/rl-rewardhacking-private.git
cd rl-rewardhacking-private/
source commands.sh 
create_all_leetcode_datasets
cd
git clone git@github.com:shawnghu/small-rl.git
cd small-rl
git checkout worktree-scale-up
uv venv
source .venv/bin/activate
uv pip install -r pyproject.toml
./vllm-patches/apply.sh
