# Reinforcement-Learning-2d-Platformer
Implementation of Reinforcement Learning  (Proximal Policy Optimization) in godot for training an agent to play a 2d platformer

Simple linear 2-D platformer made in Godot after following tutorial. 

Added Reinforcement Learning to the pipeline using PPO (Proximal Policy Optimization) from stable-baselines3

Reward shaping can be tuned in rl-platformer/scripts/game_manager.gd within the godot script editor.


**Hyperparameters: 
1. max_steps -> controls the maximum number of steps per episode

2. model = PPO("MlpPolicy", env, verbose=1, ent_coef=0.01, n_steps = 512, batch_size=64, device="cpu")
    ent_coef -> controls the entropy
    n_steps -> environment steps taken before updating the model
    device -> It is preferable to use the cpu over the gpu due to the delay in communication between the two devices causing the gpu to perform almost twice as slow.


**Files: 
rl-platformer -> folder containing the game assets, level design, game scripts, etc.
2d_platformer_venv -> contains the main python file link and requirements.

**Training Steps: 
1. Install dependencies from requirements.txt
2. Structure the folder as follows:-
    |
    |-2d_platformer_venv/
    |-rl-platformer/
    |-README.md
    |-.gitignore
3. Run the python file
4. Run the game in godot 
5. Download the model

Set fps to 240 for faster training in godot project settings -> physics process -> common


