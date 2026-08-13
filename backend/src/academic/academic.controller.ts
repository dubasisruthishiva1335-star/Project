import { Controller, Get, Query, UseGuards, Req } from '@nestjs/common';
import { ApiTags, ApiBearerAuth } from '@nestjs/swagger';
import { PrismaService } from '../prisma/prisma.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { StorageService } from '../common/storage.service';

function parseYearOrSemester(val?: string): number[] | undefined {
  if (!val) return undefined;
  const num = Number(val);
  if (isNaN(num)) return undefined;
  if (num === 1) return [1, 2];
  if (num === 2) return [3, 4];
  if (num === 3) return [5, 6];
  if (num === 4) return [7, 8];
  return [num];
}

@ApiTags('academic')
@Controller()
export class AcademicController {
  constructor(private prisma: PrismaService, private storage: StorageService) {}

  private async signUrl(s3Key?: string | null, fileUrl?: string | null): Promise<string | undefined> {
    if (s3Key) {
      return this.storage.publicUrlFor(s3Key);
    }
    if (fileUrl && fileUrl.includes('amazonaws.com/')) {
      const key = fileUrl.split('.amazonaws.com/')[1]?.split('?')[0];
      if (key) return this.storage.publicUrlFor(key);
    }
    return fileUrl || undefined;
  }

  // GET /subjects?branch=CSE&year=1 (or &semester=1)
  @Get('subjects')
  async listSubjects(
    @Query('branch') branch?: string,
    @Query('year') year?: string,
    @Query('semester') semester?: string
  ) {
    const semFilter = parseYearOrSemester(year || semester);
    const subjects = await this.prisma.subject.findMany({
      where: {
        ...(branch ? { branch } : {}),
        ...(semFilter ? { semester: { in: semFilter } } : {}),
      },
      include: { contents: true },
      orderBy: { name: 'asc' },
    });

    return Promise.all(
      subjects.map(async (subj) => ({
        ...subj,
        contents: await Promise.all(
          subj.contents.map(async (c) => ({
            ...c,
            fileUrl: await this.signUrl(c.s3Key, c.fileUrl),
          }))
        ),
      }))
    );
  }

  // GET /job-listings?type=INTERNSHIP
  @Get('job-listings')
  async listJobs(@Query('type') type?: 'INTERNSHIP' | 'PLACEMENT' | 'GOVT_JOB', @Query('branch') branch?: string) {
    const jobs = await this.prisma.jobListing.findMany({
      where: {
        ...(type ? { type } : {}),
        ...(branch ? { branch } : {}),
      },
      orderBy: { postedAt: 'desc' },
    });

    return Promise.all(
      jobs.map(async (job) => ({
        ...job,
        fileUrl: job.fileUrl ? await this.signUrl(job.s3Key, job.fileUrl) : undefined,
      }))
    );
  }

  // GET /results?year=1 (or &semester=1)
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  @Get('results')
  async getResults(@Req() req: any, @Query('year') year?: string, @Query('semester') semester?: string) {
    const hallTicket = req.user.hallTicket;
    const semFilter = parseYearOrSemester(year || semester);
    const results = await this.prisma.result.findMany({
      where: {
        hallTicket,
        ...(semFilter ? { semester: { in: semFilter } } : {}),
      },
      orderBy: { semester: 'asc' },
    });

    return Promise.all(
      results.map(async (res) => ({
        ...res,
        fileUrl: await this.signUrl(res.s3Key, res.fileUrl),
      }))
    );
  }

  // GET /aptitude?category=quantitative
  @Get('aptitude')
  async listAptitude(@Query('category') category?: string) {
    return this.prisma.aptitudeQuestion.findMany({
      where: category ? { category } : {},
      orderBy: { createdAt: 'desc' },
      take: 50,
    });
  }
}
