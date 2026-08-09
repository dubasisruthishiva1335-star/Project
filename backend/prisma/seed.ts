import { PrismaClient } from '@prisma/client';
import * as bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

async function main() {
  // Admin account for the Admin Web app
  const adminPasswordHash = await bcrypt.hash('admin123', 10);
  await prisma.user.upsert({
    where: { hallTicket: 'ADMIN001' },
    update: {},
    create: {
      hallTicket: 'ADMIN001',
      fullName: 'Shivashankar Dubasi',
      email: 'admin@myvault.app',
      passwordHash: adminPasswordHash,
      role: 'ADMIN',
      courseType: 'btech',
      branch: 'GENERAL',
      semester: 1,
    },
  });

  // A sample student
  const studentPasswordHash = await bcrypt.hash('21A91A0501', 10);
  await prisma.user.upsert({
    where: { hallTicket: '21A91A0501' },
    update: {},
    create: {
      hallTicket: '21A91A0501',
      fullName: 'Reddy Sai Kumar',
      passwordHash: studentPasswordHash,
      role: 'STUDENT',
      courseType: 'btech',
      branch: 'CSE',
      semester: 3,
    },
  });

  const subject = await prisma.subject.upsert({
    where: { id: '00000000-0000-0000-0000-000000000001' },
    update: {},
    create: {
      id: '00000000-0000-0000-0000-000000000001',
      name: 'Data Structures',
      code: 'CS201',
      branch: 'CSE',
      semester: 3,
    },
  });

  await prisma.jobListing.createMany({
    data: [
      {
        type: 'INTERNSHIP',
        title: 'Frontend Engineering Intern',
        company: 'Acme Labs',
        applyUrl: 'https://example.com/apply/acme-frontend-intern',
        branch: 'CSE',
      },
      {
        type: 'GOVT_JOB',
        title: 'Junior Assistant — TSPSC',
        company: 'Telangana State PSC',
        applyUrl: 'https://example.com/apply/tspsc-junior-assistant',
      },
    ],
    skipDuplicates: true,
  });

  console.log('Seed complete. Admin login: ADMIN001 / admin123');
  console.log('Student login: 21A91A0501 / 21A91A0501');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
