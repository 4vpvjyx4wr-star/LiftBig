import { createRouter, createWebHistory } from 'vue-router'
import { isValidDateKey, todayKey } from '@/utils/dateKey'
import AppShell from '@/components/layout/AppShell.vue'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  scrollBehavior() {
    return { top: 0 }
  },
  routes: [
    {
      path: '/',
      component: AppShell,
      children: [
        {
          path: '',
          name: 'home',
          component: () => import('@/views/HomeView.vue'),
        },
        {
          path: 'overview',
          redirect: { name: 'home' },
        },
        {
          path: 'plans',
          name: 'plans',
          component: () => import('@/views/PlansView.vue'),
        },
        {
          path: 'plates',
          name: 'plates',
          component: () => import('@/views/PlatesView.vue'),
        },
        {
          path: 'one-rep-max',
          name: 'oneRepMax',
          component: () => import('@/views/OneRepMaxView.vue'),
        },
        {
          path: 'library',
          name: 'library',
          component: () => import('@/views/LibraryView.vue'),
        },
        {
          path: 'progress',
          name: 'progress',
          component: () => import('@/views/ProgressView.vue'),
        },
      ],
    },
    {
      path: '/workout/:date?',
      name: 'workout',
      component: () => import('@/views/WorkoutLogView.vue'),
      beforeEnter: (to) => {
        const d = to.params.date
        if (d == null || d === '') {
          return { path: `/workout/${todayKey()}`, replace: true }
        }
        if (typeof d === 'string' && !isValidDateKey(d)) {
          return { path: `/workout/${todayKey()}`, replace: true }
        }
      },
    },
  ],
})

export default router
