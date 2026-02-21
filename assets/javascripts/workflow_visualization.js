// plugins/workflow_visualization/assets/javascripts/workflow_visualization.js

(function () {
  "use strict";

  // ─────────────────────────────────────────────
  // 원본 Mermaid 정의를 data 속성에 미리 저장
  // (Mermaid가 div 내용을 SVG로 교체하기 전에)
  // ─────────────────────────────────────────────
  function saveOriginalDefinitions() {
    document.querySelectorAll(".mermaid").forEach(function (el) {
      var original = el.getAttribute("data-mermaid-src");
      if (!original) {
        // textContent에서 원본 정의 추출 (아직 처리 전)
        original = el.textContent.trim();
        el.setAttribute("data-mermaid-src", original);
      }
    });
  }

  // ─────────────────────────────────────────────
  // Mermaid CDN 동적 로드
  // ─────────────────────────────────────────────
  function loadMermaid(callback) {
    if (window.mermaid) {
      callback();
      return;
    }

    var script = document.createElement("script");
    // ★ defer 속성 제거 → 로드 완료 즉시 콜백 실행 보장
    script.src =
      "https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.min.js";
    script.onload = function () {
      // ★ CDN 로드 직후 startOnLoad=false 로 강제 재설정
      //    (일부 버전은 DOMContentLoaded 에 자동 bind 시도)
      if (window.mermaid && window.mermaid.initialize) {
        window.mermaid.initialize({ startOnLoad: false });
      }
      callback();
    };
    script.onerror = function () {
      console.error("[WorkflowViz] Mermaid CDN 로드 실패. 오프라인 환경인지 확인하세요.");
      showAllFallbacks("Mermaid 라이브러리를 로드할 수 없습니다. (CDN 접근 불가)");
    };
    document.head.appendChild(script);
  }

  // ─────────────────────────────────────────────
  // Mermaid 초기화 + 렌더링
  // ─────────────────────────────────────────────
  function initMermaid() {
    // ★ 핵심: startOnLoad 반드시 false
    window.mermaid.initialize({
      startOnLoad: false,   // ← 자동 실행 방지
      theme: "default",
      securityLevel: "loose",   // SVG 클릭 이벤트 허용
      stateDiagram: {
        diagramPadding: 20,
        useMaxWidth:    true,
      },
      themeVariables: {
        fontSize:           "14px",
        primaryColor:       "#e3f2fd",
        primaryBorderColor: "#1565c0",
        primaryTextColor:   "#1a1a2e",
        lineColor:          "#1565c0",
      },
    });

    // ★ data-processed 속성이 없는 요소만 처리 (이중 실행 방지)
    var elements = Array.from(
      document.querySelectorAll(".mermaid:not([data-processed])")
    );

    if (elements.length === 0) {
      console.warn("[WorkflowViz] 처리할 .mermaid 요소가 없습니다.");
      return;
    }

    // ★ 각 요소를 개별적으로 렌더링 (한 요소 실패가 전체에 영향 안 주도록)
    elements.forEach(function (el, idx) {
      renderSingleElement(el, idx);
    });
  }

  // ─────────────────────────────────────────────
  // 단일 요소 렌더링 (개별 오류 처리)
  // ─────────────────────────────────────────────
  function renderSingleElement(el, idx) {
    // 원본 정의 읽기 (data 속성에서)
    var definition = el.getAttribute("data-mermaid-src");

    if (!definition || definition.trim() === "") {
      showFallbackMessage(el, "다이어그램 정의가 비어 있습니다.");
      return;
    }

    var id = "wv-mermaid-" + Date.now() + "-" + idx;

    // ★ mermaid.render() API 사용 (run() 대신)
    //    → 렌더 결과를 직접 받아서 삽입 (DOM 직접 수정 방식 회피)
    window.mermaid
      .render(id, definition)
      .then(function (result) {
        // result.svg 에 렌더링된 SVG 문자열이 들어있음
        el.innerHTML = result.svg;
        el.setAttribute("data-processed", "true");
        addSvgControls(el);
      })
      .catch(function (err) {
        console.error("[WorkflowViz] 렌더링 실패:", err);
        showFallbackMessage(el, err.message || "파싱 오류", definition);
      });
  }

  // ─────────────────────────────────────────────
  // 개별 오류 메시지 표시
  // ─────────────────────────────────────────────
  function showFallbackMessage(el, errorMsg, definition) {
    var wrapper = document.createElement("div");
    wrapper.className = "wv-error-panel";

    var errBox = document.createElement("div");
    errBox.className = "wv-error-message";
    errBox.innerHTML =
      "<strong>⚠️ 다이어그램 렌더링 실패</strong><br>" +
      "<span class='wv-error-detail'>" + escapeHtml(errorMsg || "") + "</span>";

    wrapper.appendChild(errBox);

    // ★ 원본 정의(data 속성)를 보여줌 — CSS가 아닌 실제 Mermaid 코드
    if (definition) {
      var toggle = document.createElement("button");
      toggle.textContent = "▼ 원본 다이어그램 정의 보기";
      toggle.className = "wv-toggle-btn";

      var pre = document.createElement("pre");
      pre.className = "wv-definition-pre";
      pre.style.display = "none";
      pre.textContent = definition;  // ← 저장해둔 원본 사용

      toggle.addEventListener("click", function () {
        if (pre.style.display === "none") {
          pre.style.display = "block";
          toggle.textContent = "▲ 원본 다이어그램 정의 숨기기";
        } else {
          pre.style.display = "none";
          toggle.textContent = "▼ 원본 다이어그램 정의 보기";
        }
      });

      wrapper.appendChild(toggle);
      wrapper.appendChild(pre);
    }

    // 기존 el 을 wrapper 로 교체
    el.parentNode.insertBefore(wrapper, el);
    el.style.display = "none";
  }

  // ─────────────────────────────────────────────
  // 전체 폴백 (CDN 로드 실패 시)
  // ─────────────────────────────────────────────
  function showAllFallbacks(msg) {
    document.querySelectorAll(".mermaid").forEach(function (el) {
      var definition = el.getAttribute("data-mermaid-src") || "";
      showFallbackMessage(el, msg, definition);
    });
  }

  // ─────────────────────────────────────────────
  // SVG 확대/축소 컨트롤
  // ─────────────────────────────────────────────
  function addSvgControls(container) {
    var svg = container.querySelector("svg");
    if (!svg) return;

    // SVG 기본 스타일
    svg.style.maxWidth = "100%";
    svg.style.height = "auto";
    svg.style.transition = "transform 0.2s ease";

    var scale = 1;

    var toolbar = document.createElement("div");
    toolbar.className = "wv-svg-toolbar";

    function makeBtn(label, title, handler) {
      var btn = document.createElement("button");
      btn.textContent = label;
      btn.title = title;
      btn.className = "wv-svg-btn";
      btn.addEventListener("click", handler);
      return btn;
    }

    toolbar.appendChild(makeBtn("＋", "확대", function () {
      scale = Math.min(3, scale + 0.2);
      svg.style.transform = "scale(" + scale + ")";
      svg.style.transformOrigin = "top center";
    }));

    toolbar.appendChild(makeBtn("－", "축소", function () {
      scale = Math.max(0.3, scale - 0.2);
      svg.style.transform = "scale(" + scale + ")";
      svg.style.transformOrigin = "top center";
    }));

    toolbar.appendChild(makeBtn("↺", "초기화", function () {
      scale = 1;
      svg.style.transform = "";
    }));

    // 다운로드 버튼
    toolbar.appendChild(makeBtn("💾 SVG 저장", "SVG 파일로 저장", function () {
      var svgData = new XMLSerializer().serializeToString(svg);
      var blob = new Blob([svgData], { type: "image/svg+xml" });
      var url = URL.createObjectURL(blob);
      var a = document.createElement("a");
      a.href = url;
      a.download = "workflow_diagram.svg";
      a.click();
      URL.revokeObjectURL(url);
    }));

    container.insertBefore(toolbar, svg);
  }

  // ─────────────────────────────────────────────
  // HTML 이스케이프 유틸
  // ─────────────────────────────────────────────
  function escapeHtml(str) {
    return str
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;");
  }

  // ─────────────────────────────────────────────
  // 진입점
  // ─────────────────────────────────────────────
  document.addEventListener("DOMContentLoaded", function () {
    var elements = document.querySelectorAll(".mermaid");
    if (elements.length === 0) return;

    // ★ Step 1: Mermaid가 DOM을 건드리기 전에 원본 정의 저장
    saveOriginalDefinitions();

    // ★ Step 2: CDN 로드 후 초기화
    loadMermaid(initMermaid);
  });

})();
