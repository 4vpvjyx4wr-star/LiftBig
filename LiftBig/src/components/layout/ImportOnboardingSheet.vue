<script setup lang="ts">
import { ref } from 'vue'
import { Capacitor } from '@capacitor/core'
import { Keyboard } from '@capacitor/keyboard'

const emit = defineEmits<{
  importFile: [file: File]
  dismiss: []
}>()

const inputId = 'liftbig-website-import'

const pasteText = ref('')
const pasteNote = ref('')

async function releaseKeyboard() {
  const active = document.activeElement
  if (active instanceof HTMLElement) active.blur()
  if (!Capacitor.isNativePlatform()) return
  try {
    await Keyboard.hide()
  } catch {
    // The keyboard is already hidden.
  }
}

function emitFile(file: File | undefined) {
  if (file) emit('importFile', file)
}

function onFile(event: Event) {
  void releaseKeyboard()
  emitFile((event.target as HTMLInputElement).files?.[0])
}

function onDrop(event: DragEvent) {
  emitFile(event.dataTransfer?.files?.[0])
}

async function pasteFromClipboard() {
  pasteNote.value = ''
  try {
    const text = (await navigator.clipboard.readText()).trim()
    if (!text) {
      pasteNote.value = 'Copy the backup on the LiftBig website first, then tap Paste.'
      return
    }
    pasteText.value = text
  } catch {
    pasteNote.value = 'Tap the box, then choose Paste. If the keyboard is open, tap Done first.'
  }
}

async function importPasted() {
  const text = pasteText.value.trim()
  if (!text) return
  await releaseKeyboard()
  emitFile(new File([text], 'liftbig-backup.json', { type: 'application/json' }))
}

async function dismiss() {
  await releaseKeyboard()
  emit('dismiss')
}
</script>

<template>
  <div
    class="fixed inset-0 z-[80] overflow-y-auto bg-black/60"
    @dragover.prevent
    @drop.prevent="onDrop"
    @pointerdown.self="releaseKeyboard"
  >
    <div class="flex min-h-full items-start justify-center p-4 pt-[max(1rem,env(safe-area-inset-top))]">
      <div
        class="w-full max-w-lg rounded-2xl border border-border bg-card p-5 shadow-xl"
        role="dialog"
        aria-labelledby="import-title"
      >
        <div class="flex items-start justify-between gap-3">
          <h2 id="import-title" class="text-lg font-black tracking-wide text-foreground">
            Bring your journal
          </h2>
          <button
            type="button"
            class="shrink-0 rounded-lg border border-border px-3 py-1.5 text-sm font-bold text-foreground"
            @click="releaseKeyboard"
          >
            Done
          </button>
        </div>
        <p class="mt-2 text-sm leading-snug text-muted">
          Copy the backup on the LiftBig website, then tap Paste. The keyboard stays closed.
        </p>
        <button
          type="button"
          class="mt-4 w-full rounded-xl bg-primary py-3 text-sm font-bold text-foreground"
          @click="pasteFromClipboard"
        >
          Paste backup
        </button>
        <p v-if="pasteNote" class="mt-2 text-sm leading-snug text-muted">{{ pasteNote }}</p>
        <textarea
          v-model="pasteText"
          rows="3"
          enterkeyhint="done"
          autocomplete="off"
          autocorrect="off"
          autocapitalize="off"
          spellcheck="false"
          class="mt-3 w-full rounded-lg border border-border bg-card-inner px-3 py-2 font-mono text-base text-foreground outline-none focus:border-primary"
          placeholder="The backup appears here"
          data-touch-input
        />
        <button
          type="button"
          class="mt-3 w-full rounded-xl bg-primary py-3 text-sm font-bold text-foreground disabled:opacity-40"
          :disabled="!pasteText.trim()"
          @click="importPasted"
        >
          Import pasted backup
        </button>
          <input
            :id="inputId"
            type="file"
            accept="application/json,.json"
            class="sr-only"
            @change="onFile"
          />
          <label
            :for="inputId"
            class="mt-2 flex w-full cursor-pointer items-center justify-center rounded-xl bg-primary py-3 text-sm font-bold text-foreground"
          >
            Import from the LiftBig website
          </label>
          <button
            type="button"
            class="mt-2 w-full rounded-xl border border-border py-3 text-sm font-bold text-foreground"
            @click="dismiss"
          >
            Start fresh on this iPhone
          </button>
      </div>
    </div>
  </div>
</template>
