# Win Video Block

Windows의 **NRPT (Name Resolution Policy Table)** 를 사용해 영상/SNS 도메인과 그 하위 도메인을 차단하는 CMD 도구입니다.

기존 hosts 방식은 `xxx.googlevideo.com` 같은 동적 서브도메인을 막지 못했습니다. 현재 버전은 도메인 suffix 규칙을 사용하므로 `.googlevideo.com` 아래의 동적 호스트도 함께 차단합니다.

## 차단 대상

- YouTube / Shorts / YouTube Music
- `*.googlevideo.com` 영상 CDN
- YouTube 이미지/API 관련 도메인
- Instagram / CDN
- TikTok / CDN
- CHZZK
- 네이버TV 진입점
- Twitch / CDN

## 사용 방법

1. `video_block.cmd`를 다운로드합니다.
2. 실행 후 UAC 관리자 권한을 허용합니다.
3. 메뉴에서 차단/해제/상태 확인을 선택합니다.

초기 비밀번호는 `bbokk` 입니다. 처음 실행 후 변경을 권장합니다.

```text
1. Block video / SNS
2. Unblock [Password required]
3. Check status
4. Change password
5. Exit
```

## 동작 원리

차단 시 Windows NRPT에 관리 태그 `WinVideoBlock`을 가진 DNS suffix 규칙을 추가합니다. 예를 들어:

```text
.googlevideo.com
.youtube.com
.cdninstagram.com
.tiktokcdn.com
.ttvnw.net
```

해당 namespace의 DNS 질의를 로컬의 사용하지 않는 DNS endpoint로 보내 정상 이름 해석을 차단합니다. 해제 시에는 `WinVideoBlock` 태그를 가진 규칙만 삭제합니다.

이전 hosts 기반 버전을 사용했던 PC에서는 차단 해제 시 기존 `VIDEO_BLOCK_BEGIN` ~ `VIDEO_BLOCK_END` 영역도 정리합니다.

## 테스트

차단 후 명령 프롬프트에서 다음과 같이 확인할 수 있습니다.

```bat
nslookup xxx.googlevideo.com
```

또는 실제 YouTube 영상 재생을 확인합니다.

## Secure DNS / DoH 주의

브라우저에서 별도의 **Secure DNS / DNS-over-HTTPS(DoH)** 서버를 강제로 지정하면 Windows의 OS DNS 정책을 우회할 가능성이 있습니다. 이 경우 Chrome/Edge의 Secure DNS를 운영체제 기본 설정을 사용하도록 설정해야 합니다.

관리자 권한을 가진 사용자는 NRPT 설정 자체를 변경할 수 있으므로 이 도구는 강력한 보안 통제보다는 가정용 접근 제한을 목적으로 합니다.

## 비밀번호

변경된 비밀번호는 평문으로 저장하지 않습니다. `%ProgramData%\VideoBlock\video_block.auth`에 랜덤 salt와 SHA-256 해시를 저장합니다.
