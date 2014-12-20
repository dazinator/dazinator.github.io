rd /s /q _deploy
if not exist _deploy (git clone https://github.com/dazinator/dazinator.github.io.git _deploy)
cd _deploy
git checkout master
cd ..
rake gen_deploy
