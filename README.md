# Win Video Block

Windows `hosts` 파일을 이용해 주요 영상/SNS 사이트 접근을 간단하게 차단하거나 해제하는 CMD 도구입니다.

## 주요 기능

- YouTube / Shorts / YouTube Music 차단
- Instagram 차단
- TikTok 차단
- CHZZK 및 네이버TV 진입점 차단
- Twitch 차단
- 관리자 권한 자동 요청
- 기존 hosts 파일 최초 1회 백업
- 차단 해제 시 비밀번호 확인
- 비밀번호 변경 기능
- 차단/해제 후 Windows DNS 캐시 자동 초기화

## 사용 방법

1. `video_block.cmd`를 다운로드합니다.
2. 파일을 실행합니다.
3. Windows UAC 창이 나오면 관리자 권한을 허용합니다.
4. 메뉴에서 원하는 기능을 선택합니다.

초기 비밀번호는 `bbokk` 입니다. 실행 후 **Change password** 메뉴에서 변경하는 것을 권장합니다.

## 메뉴

```text
1. Block video / SNS
2. Unblock [Password required]
3. Check status
4. Change password
5. Exit
```

## 비밀번호 저장

초기 비밀번호의 평문은 CMD 파일에 저장하지 않고 SHA-256 해시를 사용합니다.
비밀번호를 변경하면 `%ProgramData%\VideoBlock\video_block.auth`에 랜덤 salt와 해시가 저장됩니다.

이 기능은 일반적인 가정용 접근 제한을 위한 것이며 강력한 보안 통제 수단은 아닙니다. Windows 관리자 권한을 가진 사용자는 hosts 파일이나 설정을 직접 변경할 수 있습니다.

## hosts 방식의 한계

Windows hosts 파일은 `*.googlevideo.com` 같은 와일드카드를 지원하지 않습니다. 따라서 동적으로 생성되는 CDN 서브도메인을 사용하는 영상 서비스는 일부 트래픽이 우회될 수 있습니다.

완전한 도메인 단위 차단이 필요한 경우 DNS 필터나 공유기 수준의 자녀 보호 기능을 함께 사용하는 것이 좋습니다.

## 원상 복구

차단 해제 메뉴는 이 프로그램이 hosts 파일에 추가한 `VIDEO_BLOCK_BEGIN` ~ `VIDEO_BLOCK_END` 영역만 제거합니다.

최초 차단 시 원본 hosts 파일은 다음 위치에도 백업됩니다.

```text
%SystemRoot%\System32\drivers\etc\hosts.video_block_backup
```
