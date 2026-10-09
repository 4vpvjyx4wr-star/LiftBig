<script setup lang="ts">
import qrSrc from '@/assets/buy-me-a-coffee-qr.png'

withDefaults(
  defineProps<{
    compact?: boolean
  }>(),
  { compact: false },
)

const emit = defineEmits<{
  navigate: []
}>()

const BMC_URL = 'https://buymeacoffee.com/JTDO'
</script>

<template>
  <a
    v-if="compact"
    :href="BMC_URL"
    target="_blank"
    rel="noopener noreferrer"
    role="menuitem"
    class="flex items-center gap-2.5 border-b border-border px-3 py-2.5 text-left active:bg-card"
    @click="emit('navigate')"
  >
    <span class="min-w-0 flex-1">
      <span class="flex items-center gap-1.5 text-sm font-bold text-foreground">
        <i class="fa-solid fa-mug-hot text-primary" aria-hidden="true" />
        Buy me a coffee
      </span>
      <span class="mt-0.5 block truncate text-[10px] font-semibold text-muted">
        buymeacoffee.com/JTDO
      </span>
    </span>
    <img
      :src="qrSrc"
      alt="Buy Me a Coffee QR code"
      class="h-[4.5rem] w-[4.5rem] shrink-0 rounded-md bg-white p-0.5"
      width="72"
      height="72"
    />
  </a>
  <section
    v-else
    class="mb-4 rounded-2xl border border-border bg-card-inner p-4"
  >
    <h3 class="mb-1 text-[11px] font-extrabold uppercase tracking-wider text-foreground/80">
      Support LiftBig
    </h3>
    <p class="mb-3 text-[11px] leading-snug text-muted">
      If this app helps your training, please consider buying me a coffee and sharing it with your friends.
    </p>
    <div class="flex items-center gap-3">
      <a
        :href="BMC_URL"
        target="_blank"
        rel="noopener noreferrer"
        class="min-w-0 flex-1 rounded-xl border border-border bg-card px-3 py-3 text-sm font-bold text-foreground transition-colors hover:border-primary/50"
        @click="emit('navigate')"
      >
        <span class="flex items-center gap-2">
          <i class="fa-solid fa-mug-hot text-primary" aria-hidden="true" />
          Buy me a coffee
        </span>
        <span class="mt-1 block text-[11px] font-semibold text-muted">
          buymeacoffee.com/JTDO
        </span>
      </a>
      <img
        :src="qrSrc"
        alt="Buy Me a Coffee QR code"
        class="h-28 w-28 shrink-0 rounded-xl bg-white p-1"
        width="112"
        height="112"
      />
    </div>
  </section>
</template>
