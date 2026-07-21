import argparse
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

    logging.debug("Detecting CUDA architectures...")
    device_capabilities = set()
    for i in range(torch.cuda.device_count()):
        major, minor = torch.cuda.get_device_capability(i)
        device_capabilities.add((major, minor))

    env_file_contents = ""
    caps = sorted(list(device_capabilities))
    if caps:
        torch_arch_list = ";".join([f"{major}.{minor}" for major, minor in caps])
        env_file_contents += f'export TORCH_CUDA_ARCH_LIST="{torch_arch_list}"\n'
        logging.info(f"TORCH_CUDA_ARCH_LIST={torch_arch_list}")

        cmake_arch_list = ";".join([f"{major}{minor}" for major, minor in caps])
        env_file_contents += f'export CMAKE_CUDA_ARCHITECTURES="{cmake_arch_list}"\n'
    else:
        raise RuntimeError("No CUDA devices found")

    logging.debug("Writing environment variables to file...")
    with open(args.output_file, "w") as f:
        f.write(env_file_contents)
        logging.info(f"Wrote environment variables to {args.output_file}")


if __name__ == "__main__":
    main()
