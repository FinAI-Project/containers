import argparse
import collections
import logging

import torch

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


def main():
    parser = argparse.ArgumentParser(description="Generate CUDA environment variable file", formatter_class=argparse.RawDescriptionHelpFormatter, epilog=__doc__)
    parser.add_argument("output_file", nargs="?", default="./cuda.env", help="Output env file path (default: ./cuda.env)")
    args = parser.parse_args()

    if not torch.cuda.is_available():
        raise RuntimeError("CUDA is not available, cannot detect GPU architectures")

    gpu_count = torch.cuda.device_count()
    logger.info(f"Detected {gpu_count} CUDA device(s)")

    gpu_counter = collections.Counter()
    device_capabilities = set()
    for i in range(gpu_count):
        major, minor = torch.cuda.get_device_capability(i)
        device_capabilities.add((major, minor))

        name = torch.cuda.get_device_name(i)
        gpu_counter[name] += 1

    env_lines = []

    # TORCH_CUDA_ARCH_LIST
    caps = sorted(device_capabilities)
    if caps:
        torch_arch_list = ";".join([f"{major}.{minor}" for major, minor in caps])
        env_lines.append(f'export TORCH_CUDA_ARCH_LIST="{torch_arch_list}"')
        logger.info(f"TORCH_CUDA_ARCH_LIST={torch_arch_list}")

        cmake_arch_list = ";".join([f"{major}{minor}" for major, minor in caps])
        env_lines.append(f'export CMAKE_CUDA_ARCHITECTURES="{cmake_arch_list}"')
    else:
        raise RuntimeError("No CUDA devices found")

    gpu_model_parts = [f"{count}x{model}" for model, count in gpu_counter.items()]
    gpu_model_str = ";".join(gpu_model_parts)
    env_lines.append(f'export CUDA_GPU_MODELS="{gpu_model_str}"')

    with open(args.output_file, "w") as f:
        f.write("\n".join(env_lines))

    logger.info(f"Wrote environment variables to {args.output_file}")


if __name__ == "__main__":
    main()
