#include "angle.h"

gvec(float,4) ang_eul2quat(float p, float y, float r) {
	/* there's some weird stuff happening here.. */
	gvec(float,4) sins, coss;
	gvec(float,4) vals;
	vals[0] = p;
	vals[1] = y;
	vals[2] = r;
	vals /= 360.0f;

	SINCOSPIvf3(vals, &sins, &coss);

	gvec(float,4) roll1 = {coss[0], sins[0], coss[0], coss[0]};
	gvec(float,4) pitch1 = {coss[1], coss[1], sins[1], coss[1]};
	gvec(float,4) yaw1 = {coss[2], coss[2], coss[2], sins[2]};

	gvec(float,4) roll2 = {sins[0], coss[0], sins[0], sins[0]};
	gvec(float,4) pitch2 = {sins[1], sins[1], coss[1], sins[1]};
	gvec(float,4) yaw2 = {sins[2], sins[2], sins[2], coss[2]};

#ifdef __FMA__
	gvec(float,4) q1 = roll1 * pitch1;
#else
	gvec(float,4) q1 = roll1 * pitch1 * yaw1;
#endif /* __FMA__ */
	gvec(float,4) q2 = roll2 * pitch2 * yaw2;
	gvec(float,4) q;

#ifdef __FMA__
	/* uses single instruction here */
	union {
		__m128 mm;
		gvec(float,4) vec;
	} qin, qin1, qin2;
	qin1.vec = q1;
	qin2.vec = q2;
	qin.vec = yaw1;
	qin.mm = _mm_fmaddsub_ps(qin1.mm, qin.mm, qin2.mm);
	q = qin.vec;
#elif defined(__SSE3__) /* !__FMA__ */
	/* uses single instruction here */
	union {
		__m128 mm;
		gvec(float,4) vec;
	} qin, qin1, qin2;
	qin1.vec = q1;
	qin2.vec = q2;
	qin.mm = _mm_addsub_ps(qin1.mm, qin2.mm);
	q = qin.vec;
#else /* !__SSE3__ */
	/* has to do multiple otherwise */
	/* I think something's backwards here.. */
	q[0] = q1[0] - q2[0];
	q[1] = q1[1] + q2[1];
	q[2] = q1[2] - q2[2];
	q[3] = q1[3] + q2[3];
#endif

	return q;
}

gvec(float,4) ang_eulnoroll2quat(float p, float y) {
	gvec(float,2) sins, coss;
	gvec(float,2) vals = {p, y};
	vals /= 360.0f;

	SINCOSPIvf2(vals, &sins, &coss);

	gvec(float,4) roll = {coss[0], sins[0], coss[0], sins[0]};
	gvec(float,4) pitch = {coss[1], coss[1], sins[1], sins[1]};

	return roll * pitch;
}

gvec(float,4) ang_axisang2quat(gvec(float,4) a) {
	float sina, cosa;
	SINCOSPIf(a[0] / 360.0f, &sina, &cosa);

	gvec(float,4) asqr = a * a;

	/* compiler will transform this hopefully */
	a /= sqrtf(asqr[1] + asqr[2] + asqr[3]);
	a[0] = 1.0f;

	return (gvec(float,4)){cosa, sina, sina, sina} * a;
}

gvec(float,4) ang_quat2axisang(gvec(float,4) q) {
	if (q[0] != 1.0f) {
		float ang = acosf(q[0]);

		q /= sinf(ang);
		q[0] = ang * (360.0f / (float)M_PI);

		return q;
	} else
		return (gvec(float,4)){0.0f, 1.0f, 0.0f, 0.0f};
}

gvec(float,4) ang_quatmul(gvec(float,4) r, gvec(float,4) s) {
#ifdef __FMA__
	gvec(float,4) t = {
		r[0] * s[0] - r[1] * s[1],
		r[0] * s[1] + r[1] * s[0],
		r[0] * s[2] + r[1] * s[3],
		r[0] * s[3] - r[1] * s[2]
	};

	union {
		gvec(float,4) vec;
		__m128 mm;
	} r2, s2, rs3;
	r2.vec = (gvec(float,4)){r[2], r[2], r[2], r[2]};
	s2.vec = (gvec(float,4)){s[2], s[3], s[0], s[1]};
	rs3.vec = (gvec(float,4)){
		r[3] * s[3],
		r[3] * s[2],
		r[3] * s[1],
		r[3] * s[0]
	};

	rs3.mm = _mm_fmaddsub_ps(r2.mm, s2.mm, rs3.mm);
	t[0] -= rs3.vec[0];
	t[1] -= rs3.vec[1];
	t[2] += rs3.vec[2];
	t[3] += rs3.vec[3];
#elif defined(__SSE3__)
	gvec(float,4) t = {
		r[0] * s[0] - r[1] * s[1] - r[2] * s[2],
		r[0] * s[1] + r[1] * s[0] - r[2] * s[3],
		r[0] * s[2] + r[1] * s[3] + r[2] * s[0],
		r[0] * s[3] - r[1] * s[2] + r[2] * s[1]
	};

	union {
		gvec(float,4) vec;
		__m128 mm;
	} rs3, t_un;
	rs3.vec = (gvec(float,4)){
		r[3] * s[3],
		r[3] * s[2],
		r[3] * s[1],
		r[3] * s[0]
	};
	t_un.vec = t;

	t_un.mm = _mm_addsub_ps(t_un.mm, rs3.mm);
	t = t_un.vec;
#else
	gvec(float,4) t = {
		r[0] * s[0] - r[1] * s[1] - r[2] * s[2] - r[3] * s[3],
		r[0] * s[1] + r[1] * s[0] - r[2] * s[3] + r[3] * s[2],
		r[0] * s[2] + r[1] * s[3] + r[2] * s[0] - r[3] * s[1],
		r[0] * s[3] - r[1] * s[2] + r[2] * s[1] + r[3] * s[0]
	};
#endif

	return t;
}
