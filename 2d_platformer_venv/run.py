import gymnasium as gym
import numpy as np
import socket, json
from stable_baselines3 import PPO

class PlatformerEnv(gym.Env):
    def __init__(self):
        super().__init__()
        self.step_count = 0
        self.max_steps = 10000
        self._buffer = b""
        self.action_space = gym.spaces.Discrete(6)
        self.observation_space = gym.spaces.Box(
            low=-np.inf, high=np.inf, shape=(6,), dtype=np.float32
        )

        self.server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self.server.bind(("localhost", 9999))
        self.server.listen(1)
        print("Waiting for Godot to connect...")
        self.conn, _ = self.server.accept()
        print("Godot connected. Running model...")

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
        data = self._buffer
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

    model = PPO.load("platformer_ppo", env=env)
    print("Model loaded. Starting evaluation...")

    num_episodes = 10

    for episode in range(num_episodes):
        obs, _ = env.reset()
        total_reward = 0
        done = False

        while not done:
            action, _ = model.predict(obs, deterministic=True)
            obs, reward, done, truncated, _ = env.step(action)
            total_reward += reward
            if truncated:
                break

        print(f"Episode {episode + 1}: Total Reward = {total_reward:.2f}")

    print("Evaluation done.")
    env.close()