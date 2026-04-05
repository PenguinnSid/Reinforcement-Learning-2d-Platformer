import gymnasium as gym
import numpy as np
import socket, json
from stable_baselines3 import PPO
import torch

class PlatformerEnv(gym.Env):
    def __init__(self):
        super().__init__()
        self.step_count = 0
        self.max_steps = 10000
        self._buffer = b""
        self.action_space = gym.spaces.Discrete(6)  # 0=left, 1=right, 2=jump, 3=idle, 4=jump + left, 5=jump + right
        self.observation_space = gym.spaces.Box(
            low=-np.inf, high=np.inf, shape=(6,), dtype=np.float32
        )  # [player_x, player_y, velocity_x, velocity_y, coin_x, coin_y]

        self.server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)  # avoid "address in use" on restart
        self.server.bind(("localhost", 9999))
        self.server.listen(1)
        print("Waiting for Godot to connect...")
        self.conn, _ = self.server.accept()
        print("Godot connected. Starting training...")


    def reset(self, seed=None):
        self._send({"command": "reset"})
        data = self._recv()
        self.step_count = 0
        obs = np.array(data["state"], dtype=np.float32)
        return obs, {}

    def step(self, action):
        self._send({"action": int(action)})
        data = self._recv()
        obs = np.array(data["state"], dtype=np.float32)
        reward = float(data["reward"])
        done = bool(data["done"])
        self.step_count += 1
        truncated = self.step_count >= self.max_steps
        return obs, reward, done, truncated, {}

    def _send(self, data):
        msg = (json.dumps(data) + "\n").encode()
        self.conn.sendall(msg)

    def _recv(self):
        data = self._buffer  # start with any leftover from last call
        while b"\n" not in data:
            chunk = self.conn.recv(4096)
            if not chunk:
                raise ConnectionError("Godot disconnected")
            data += chunk
        first, remainder = data.split(b"\n", 1)
        self._buffer = remainder
        return json.loads(first.decode())

    def close(self):
        self.conn.close()
        self.server.close()


if __name__ == "__main__":
    env = PlatformerEnv()
    model = PPO("MlpPolicy", env, verbose=1, ent_coef=0.05, n_steps = 512, batch_size=64, device="cpu")
    model.learn(total_timesteps=500_000)
    model.save("platformer_ppo")
    print("Training done, model saved.")
    env.close()