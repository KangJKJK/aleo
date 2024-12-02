#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # 색상 초기화

# 초기 선택 메뉴
echo -e "${YELLOW}옵션을 선택하세요:${NC}"
echo -e "${GREEN}1: Aleo 노드 새로 설치${NC}"
echo -e "${GREEN}2: Aleo 노드 삭제${NC}"
read -p "선택 (1, 2): " option

if [ "$option" == "1" ]; then
    echo "Aleo 노드 새로 설치를 선택했습니다."
    
    echo -e "${YELLOW}NVIDIA 드라이버 설치 옵션을 선택하세요:${NC}"
    echo -e "1: 일반 그래픽카드 (RTX, GTX 시리즈) 드라이버 설치"
    echo -e "2: 서버용 GPU (T4, L4, A100 등) 드라이버 설치"
    echo -e "3: 기존 드라이버 및 CUDA 완전 제거"
    echo -e "4: 드라이버 설치 건너뛰기"
    
    while true; do
        read -p "선택 (1, 2, 3, 4): " driver_option
        
        case $driver_option in
            1)
                sudo apt update
                sudo apt install -y nvidia-utils-550
                sudo apt install -y nvidia-driver-550
                sudo apt-get install -y cuda-drivers-550 
                sudo apt-get install -y cuda-12-3
                ;;
            2)
                distribution=$(. /etc/os-release;echo $ID$VERSION_ID | sed -e 's/\.//g')
                wget https://developer.download.nvidia.com/compute/cuda/repos/$distribution/x86_64/cuda-keyring_1.0-1_all.deb
                sudo dpkg -i cuda-keyring_1.0-1_all.deb
                sudo apt-get update
                sudo apt install -y nvidia-utils-550-server
                sudo apt install -y nvidia-driver-550-server
                sudo apt-get install -y cuda-12-3
                ;;
            3)
                echo "기존 드라이버 및 CUDA를 제거합니다..."
                sudo apt-get purge -y nvidia*
                sudo apt-get purge -y cuda*
                sudo apt-get purge -y libnvidia*
                sudo apt autoremove -y
                sudo rm -rf /usr/local/cuda*
                echo "드라이버 및 CUDA가 완전히 제거되었습니다."
                ;;
            4)
                echo "드라이버 설치를 건너뜁니다."
                break
                ;;
            *)
                echo "잘못된 선택입니다. 다시 선택해주세요."
                continue
                ;;
        esac
        
        if [ "$driver_option" != "4" ]; then
            echo -e "\n${YELLOW}NVIDIA 드라이버 설치 옵션을 선택하세요:${NC}"
            echo -e "1: 일반 그래픽카드 (RTX, GTX 시리즈) 드라이버 설치"
            echo -e "2: 서버용 GPU (T4, L4, A100 등) 드라이버 설치"
            echo -e "3: 기존 드라이버 및 CUDA 완전 제거"
            echo -e "4: 드라이버 설치 건너뛰기"
        fi
    done
    
        # CUDA 툴킷 설치 여부 확인
        if command -v nvcc &> /dev/null; then
            echo -e "${GREEN}CUDA 툴킷이 이미 설치되어 있습니다.${NC}"
            nvcc --version
            read -p "CUDA 툴킷을 다시 설치하시겠습니까? (y/n): " reinstall_cuda
            if [ "$reinstall_cuda" == "y" ]; then
                sudo apt-get install -y nvidia-cuda-toolkit
            fi
        else
            echo -e "${YELLOW}CUDA 툴킷을 설치합니다...${NC}"
            sudo apt-get install -y nvidia-cuda-toolkit
        fi

        read -p "윈도우라면 파워셸을 관리자권한으로 열어서 다음 명령어들을 입력하세요"
        echo "wsl --set-default-version 2"
        echo "wsl --shutdown"
        echo "wsl --update"
    
        # 사용자 입력 받기
        read -p "GPU 종류를 선택하세요 (1: NVIDIA, 2: AMD): " gpu_choice
        read -p "Aleo 지갑 주소를 입력하세요(puzzle월렛을 받으세요): " wallet_address
        read -p "채굴자 이름을 입력하세요: " miner_name
    
        # GPU 선택에 따른 다운로드 및 설치
        if [ "$gpu_choice" == "1" ]; then
            echo "NVIDIA GPU 마이너를 다운로드합니다..."
            wget https://github.com/6block/zkwork_aleo_gpu_worker/releases/download/cuda-v0.2.5-hotfix2/aleo_prover-v0.2.5_cuda_full_hotfix2.tar.gz
            tar -zvxf aleo_prover-v0.2.5_cuda_full_hotfix2.tar.gz
        elif [ "$gpu_choice" == "2" ]; then
            echo "AMD GPU 마이너를 다운로드합니다..."
            wget wget https://github.com/6block/zkwork_aleo_gpu_worker/releases/download/ocl-v0.2.5/aleo_prover-v0.2.5_ocl.tar.gz
            tar -zvxf aleo_prover-v0.2.5_ocl.tar.gz
        else
            echo "잘못된 선택입니다."
            exit 1
        fi
    
        # aleo_prover 디렉토리로 이동
        cd aleo_prover
    
        # inner_prover.sh 파일 수정
        sed -i "s/reward_address=.*/reward_address=$wallet_address/" inner_prover.sh
        sed -i "s/custom_name=.*/custom_name=\"$miner_name\"/" inner_prover.sh

        # UFW 활성화 (아직 활성화되지 않은 경우)
        sudo ufw enable
        
        # 현재 사용 중인 포트 확인 및 허용
        echo -e "${GREEN}현재 사용 중인 포트를 확인합니다...${NC}"

        # TCP 포트 확인 및 허용
        echo -e "${YELLOW}TCP 포트 확인 및 허용 중...${NC}"
        sudo ss -tlpn | grep LISTEN | awk '{print $4}' | cut -d':' -f2 | while read port; do
            echo -e "TCP 포트 ${GREEN}$port${NC} 허용"
            sudo ufw allow $port/tcp
        done

        # UDP 포트 확인 및 허용
        echo -e "${YELLOW}UDP 포트 확인 및 허용 중...${NC}"
        sudo ss -ulpn | grep LISTEN | awk '{print $4}' | cut -d':' -f2 | while read port; do
            echo -e "UDP 포트 ${GREEN}$port${NC} 허용"
            sudo ufw allow $port/udp
        done

        echo -e "${YELLOW}마이너를 시작합니다...${NC}"
        sudo touch prover.log && sudo chown $USER:$USER prover.log && sudo chmod 666 prover.log
        sudo chmod +x run_prover.sh
        ./run_prover.sh
    
        # 로그 확인
        echo "3초 후 마이닝 로그를 표시합니다..."
        sleep 3

        # 로그 실시간 확인
        tail -f prover.log

        echo "해당사이트에서 대시보드를 확인하세요: https://zk.work/en/aleo/"
        echo -e "${GREEN}스크립트작성자: https://t.me/kjkresearch${NC}"

elif [ "$option" == "2" ]; then
    echo "Aleo 노드 삭제를 선택했습니다."

    # 작업 디렉토리 삭제
    rm -rf ~/aleo_prover
    echo "Aleo 마이너 디렉토리가 삭제되었습니다."

    # 1. sudo를 사용하여 프로세스 종료
    sudo kill $(pgrep aleo_prover)

    # 2. 여전히 실행 중이라면 강제 종료
    sudo pkill -f "aleo_prover"
    sudo pkill -9 aleo_prover

else
    echo "잘못된 선택입니다."
    exit 1
fi
