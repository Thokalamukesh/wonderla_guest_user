"use client";

import { useEffect } from "react";

/** Adds one-time reveal motion to marked guest cards as they enter the viewport. */
const ScrollRevealEffects = () => {
  useEffect(() => {
    const root = document.querySelector("[data-guest-experience]");
    if (!root) return;

    const reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    if (reducedMotion || !("IntersectionObserver" in window)) {
      root.querySelectorAll("[data-scroll-reveal]").forEach((card) => card.classList.add("is-visible"));
      return;
    }

    const observer = new IntersectionObserver((entries) => {
      entries.forEach((entry) => {
        if (!entry.isIntersecting) return;
        entry.target.classList.add("is-visible");
        observer.unobserve(entry.target);
      });
    }, { threshold: 0.12, rootMargin: "0px 0px -36px 0px" });

    const observeCards = () => {
      root.querySelectorAll<HTMLElement>("[data-scroll-reveal]:not([data-reveal-observed])").forEach((card) => {
        card.dataset.revealObserved = "true";
        observer.observe(card);
      });
    };

    observeCards();
    const mutations = new MutationObserver(observeCards);
    mutations.observe(root, { childList: true, subtree: true });

    return () => {
      mutations.disconnect();
      observer.disconnect();
    };
  }, []);

  return null;
};

export default ScrollRevealEffects;
